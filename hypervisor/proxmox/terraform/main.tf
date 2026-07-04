resource "proxmox_virtual_environment_container" "pihole_01" {
  node_name = "proxmox"
  vm_id     = 105
  tags      = ["community-script", "os"]
  start_on_boot = true
  started       = true
  unprivileged  = true
  memory {
    dedicated = 512
    swap      = 512
  }
  disk {
    datastore_id = "local"
    size         = 6
  }
  network_interface {
    name    = "eth0"
    bridge  = "vmbr0"
    mac_address = "BC:24:11:3D:A3:9A"
    firewall = false
  }
  initialization {
    hostname = "pihole-01"
    ip_config {
      ipv4 {
        address = "10.0.0.20/24"
        gateway = "10.0.0.1"
      }
    }
    dns {
      domain = "1.1.1.1"
      servers = ["9.9.9.9"]
    }
  }
  operating_system {
    type = "ubuntu"
  }
}

resource "proxmox_virtual_environment_vm" "automation_01" {
  node_name = "proxmox"
  vm_id     = 999
  name      = "automation-01"
  bios      = "ovmf"
  on_boot   = true
  scsi_hardware = "virtio-scsi-single"
  tablet_device = true
  cpu {
    cores = 2
    sockets = 1
    type = "host"
  }
  memory {
    dedicated = 4096
    floating = 2048
  }
  agent {
    enabled = true
    type = "virtio"
  }
  disk {
    datastore_id = "local"
    size         = 60
    interface    = "scsi0"
    file_format  = "qcow2"
    discard      = "on"
    ssd          = true
  }
  network_device {
    bridge = "vmbr0"
    firewall = true
  }
  efi_disk {
    datastore_id = "local"
    file_format  = "qcow2"
    type         = "4m"
  }
}

resource "proxmox_virtual_environment_vm" "colmado_db" {
  node_name = "proxmox"
  vm_id     = 101
  name      = "TUMANDAO"
  bios      = "seabios"
  on_boot   = true
  scsi_hardware = "virtio-scsi-single"
  tablet_device = true
  cpu {
    cores = 2
    sockets = 1
    type = "host"
    limit = 1.5
  }
  memory {
    dedicated = 8192
    floating = 0
  }
  agent {
    enabled = true
    type = "virtio"
  }
  disk {
    datastore_id = "local"
    size         = 50
    interface    = "scsi0"
    file_format  = "qcow2"
    discard      = "on"
    ssd          = false
  }
  network_device {
    bridge = "vmbr0"
    firewall = true
  }
}

resource "proxmox_virtual_environment_vm" "docker_01" {
  node_name = "proxmox"
  vm_id     = 102
  name      = "docker-01"
  bios      = "ovmf"
  tags      = ["community-script"]
  on_boot   = true
  scsi_hardware = "virtio-scsi-pci"
  tablet_device = false
  cpu {
    cores = 4
    sockets = 1
    type = "qemu64"
  }
  memory {
    dedicated = 4096
    floating = 2048
  }
  agent {
    enabled = true
    type = "virtio"
  }
  disk {
    datastore_id = "local"
    size         = 150
    interface    = "scsi0"
    file_format  = "qcow2"
    discard      = "ignore"
    ssd          = false
  }
  network_device {
    bridge = "vmbr0"
    firewall = false
  }
  efi_disk {
    datastore_id = "local"
    file_format  = "qcow2"
    type         = "4m"
  }
}

resource "proxmox_virtual_environment_vm" "security_01" {
  node_name = "proxmox"
  vm_id     = 109
  name      = "security-01"
  bios      = "seabios"
  on_boot   = true
  scsi_hardware = "virtio-scsi-single"
  tablet_device = true
  cpu {
    cores = 2
    sockets = 1
    type = "qemu64"
  }
  memory {
    dedicated = 4096
    floating = 0
  }
  agent {
    enabled = true
    type = "virtio"
  }
  disk {
    datastore_id = "local"
    size         = 60
    interface    = "scsi0"
    file_format  = "qcow2"
    discard      = "on"
    ssd          = true
  }
  network_device {
    bridge = "vmbr0"
    firewall = false
  }
  initialization {
    interface = "ide2"
    datastore_id = "local"
    user_account {
      username = "yzee"
      keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJTNTA7Z79TVV4SCuHJ7+udf6xCI0uyDb5vaCTPMZEyN yzee-mac-security01", "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINKcp4DzXr8iAYsMp/IshElBUJPgr9rXqqV5gElgTR7v automation-01 ansible key rotated"]
    }
    ip_config {
      ipv4 {
        address = "10.0.0.40/24"
        gateway = "10.0.0.1"
      }
    }
    dns {
      domain = "local.ycianno.uk"
      servers = ["10.0.0.20"]
    }
  }
}
