resource "proxmox_virtual_environment_vm" "docker_01" {
  node_name = "proxmox"
  vm_id     = 102
  name      = "docker-01"
}

resource "proxmox_virtual_environment_vm" "automation_01" {
  node_name = "proxmox"
  vm_id     = 999
  name      = "automation-01"
}

resource "proxmox_virtual_environment_vm" "security_01" {
  node_name = "proxmox"
  vm_id     = 109
  name      = "security-01"
}

resource "proxmox_virtual_environment_vm" "colmado_db" {
  node_name = "proxmox"
  vm_id     = 101
  name      = "TUMANDAO"
}

resource "proxmox_virtual_environment_container" "pihole_01" {
  node_name = "proxmox"
  vm_id     = 105
}
