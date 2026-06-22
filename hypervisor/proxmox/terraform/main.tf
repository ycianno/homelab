resource "proxmox_virtual_environment_container" "wazuh_manager" {
  node_name = "proxmox"
  vm_id     = 110

  initialization {
    hostname = "security-01"

    ip_config {
      ipv4 {
        address = "10.0.0.40/24"
        gateway = "10.0.0.1"
      }
    }
  }

  network_interface {
    name = "eth0"
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096 # Recommended minimum for Wazuh Manager
  }

  disk {
    datastore_id = "local-lvm"
    size         = 30
  }
}
