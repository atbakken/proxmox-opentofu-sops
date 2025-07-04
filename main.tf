variable "cloudinit_template_name" {
  type = string
}

variable "name_prefix" {
  type = string
}

locals {
  proxmox_node_list = jsondecode(data.sops_file.secrets.data["proxmox_nodes"])
  num_proxmox_nodes = length(local.proxmox_node_list)
}

resource "proxmox_vm_qemu" "vm-cluster" {
  count = 3

  lifecycle {
    precondition {
      condition     = local.num_proxmox_nodes > 0
      error_message = "The 'proxmox_nodes' list in secrets.enc.yaml must not be empty and must be a valid JSON array string."
    }
  }

  name        = "${var.name_prefix}${count.index + 1}"
  target_node = element(local.proxmox_node_list, count.index % local.num_proxmox_nodes)
  clone       = var.cloudinit_template_name
  full_clone  = true
  os_type     = "cloud-init"
  agent       = 1
  cpu_type    = "host"
  cores       = 4
  memory      = 4096
  scsihw      = "virtio-scsi-pci"
  bootdisk    = "scsi0"
  bios        = "ovmf"

  serial {
    id   = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }

  disk {
    slot       = "scsi0"
    size       = "40G"
    type       = "disk"
    storage    = "ceph-pool"
    discard    = true
    emulatessd = true
  }

  disk {
    slot    = "ide2"
    type    = "cloudinit"
    storage = "ceph-pool"
  }

  network {
    model  = "virtio"
    id     = 0
    bridge = "vmbr0"
    tag    = 50
  }

  network {
    model  = "virtio"
    id     = 1
    bridge = "vmbr1"
    tag    = 300
    mtu    = 9000
  }

  network {
    model  = "virtio"
    id     = 2
    bridge = "vmbr1"
    tag    = 210
    mtu    = 9000
  }

  pci {
    id          = 0
    mapping_id  = "vGPU-pool"
    primary_gpu = true
  }

  ciuser       = data.sops_file.secrets.data["ciuser"]
  cipassword   = data.sops_file.secrets.data["cipassword"]
  ciupgrade    = true
  ipconfig0    = "ip=192.168.50.1${count.index + 1}/24,gw=192.168.50.1"
  ipconfig1    = "ip=10.20.20.5${count.index + 1}/24"
  ipconfig2    = "ip=10.10.10.5${count.index + 1}/24"
  searchdomain = data.sops_file.secrets.data["searchdomain"]
  nameserver   = "192.168.56.2 192.168.40.42"

  sshkeys = <<EOF
  ${data.sops_file.secrets.data["ssh_key"]}
  EOF
}
