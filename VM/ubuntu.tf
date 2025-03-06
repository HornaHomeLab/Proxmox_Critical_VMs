module "ubuntu_vm_200" {
  source = "github.com/HornaHomeLab/Terraform_Modules/Ubuntu-VM"

  proxmox_api_token_id     = var.proxmox_api_token_id
  proxmox_api_token_secret = var.proxmox_api_token_secret
  proxmox_api_url          = var.proxmox_api_url
  ssh_pubkey_file          = "./../secrets/id_rsa.pub"
  default_password_file    = "./../secrets/proxmox_password.txt"

  vmid         = 200
  vm_name      = "services-local"
  vm_desc      = "Ubuntu VM to host local (single-conatiner) services"
  tags         = ["critical"]
  memory       = "8192"
  ip_address   = "10.0.10.200"
  cidr_netmask = "24"
  gateway      = "10.0.10.1"
  dns_servers  = ["10.0.10.10", "1.1.1.1", "8.8.8.8"]
}
