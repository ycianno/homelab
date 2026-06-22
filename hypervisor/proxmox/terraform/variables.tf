variable "proxmox_endpoint" {
  description = "The endpoint URL of your Proxmox VE server"
  type        = string
}

variable "proxmox_api_token" {
  description = "The API token for Proxmox VE (root@pam!terraform-token=secret)"
  type        = string
  sensitive   = true
}
