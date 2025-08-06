#cloud-config
hostname: ${hostname}
fqdn: ${hostname}.int.bakkens.ca
manage_etc_hosts: true
users:
  - name: ansible
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys:
      - ssh-rsa AAAAB3...yourkey... rest_of_key
package_update: false
package_upgrade: false

fs_setup:
  - device: /dev/sdb
    filesystem: ext4
    label: longhorn-data

mounts:
  - [ /dev/sdb, /var/lib/longhorn, ext4, "defaults", "0", "2" ]

runcmd:
  - mkdir -p /var/lib/longhorn
  - mount /var/lib/longhorn
  - [hostnamectl, set-hostname, ${hostname}]
