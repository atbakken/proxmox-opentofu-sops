variable "cloudinit_template_name" {
  type = string
}

resource "proxmox_vm_qemu" "k8s-1" {
  count = 1
  name = "k8s-1${count.index + 1}"
  target_node = data.sops_file.secrets.data["proxmox_node"]
  clone = var.cloudinit_template_name
  full_clone = true
  os_type = "cloud-init"
  agent = 1
  cpu_type = "host"
  cores = 4
  memory = 4096
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
  bios = "ovmf"

  serial {
    id = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }

  disk {
    slot = "scsi0"
    size = "40G"
    type = "disk"
    storage = "ceph-pool"
    discard = true
    emulatessd = true
  }

  disk {
    slot = "ide2"
    type = "cloudinit"
    storage = "ceph-pool"
  }

  network {
    model = "virtio"
    id = 0
    bridge = "vmbr0"
    tag = 50
  } 

  network {
    model = "virtio"
    id = 1
    bridge = "vmbr1"
    tag = 300
    mtu = 9000
  } 
  
  network {
    model = "virtio"
    id = 2
    bridge = "vmbr1"
    tag = 210
    mtu = 9000
  } 
  
  pci {
    id = 0
    mapping_id = "vGPU-pool"
    primary_gpu = true
  }

  ciuser = "ansible"
  cipassword = "test1"
  ciupgrade = true
  ipconfig0 = "ip=192.168.50.1${count.index + 1}/24,gw=192.168.50.1"
  ipconfig1 = "ip=10.20.20.5${count.index + 1}/24"
  ipconfig2 = "ip=10.10.10.5${count.index + 1}/24"
  searchdomain = "int.bakkens.ca"
  nameserver = "192.168.56.2 192.168.40.42"

  sshkeys = <<EOF
  ${data.sops_file.secrets.data["ssh_key"]}
  EOF
}
