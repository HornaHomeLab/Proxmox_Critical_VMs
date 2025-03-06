variable "docker_machine_ip" {
  description = "IP address of the Docker machine"
  type = string
  default = "10.0.10.200"
}

variable "root_access_token_file" {
  description = "The path to the default password file"
  type        = string
  default     = "./../secrets/vault_root_token.txt"
}

variable "proxmox_user_pubkey_file" {
  description = "The path to the Proxmox user's public key file"
  type        = string
  default     = "./../secrets/id_rsa.pub"
}

variable "proxmox_user_privkey_file" {
  description = "The path to the Proxmox user's private key file"
  type        = string
  default     = "./../secrets/id_rsa"
}

variable "proxmox_user_password_file" {
  description = "The path to the Proxmox user's private key file"
  type        = string
  default     = "./../secrets/proxmox_password.txt"
}