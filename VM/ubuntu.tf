# Configure the Vault provider with AppRole authentication
provider "vault" {
  address = "http://vault.horna.local"

  # AppRole authentication
  auth_login {
    path = "auth/approle/login"
    parameters = {
      role_id   = "1bc0add6-85be-540a-c266-eddf8841a704"
      secret_id = "dde13473-c32e-4fd7-1fdc-7b2f6b1e36f5"
    }
  }

}

# Retrieve Proxmox credentials from Vault
data "vault_generic_secret" "proxmox_credentials" {
  path = "Infrastructure-Access/proxmox"
}

module "ubuntu_vm_200" {
  source = "github.com/HornaHomeLab/Terraform_Modules/Ubuntu-VM"

  proxmox_api_token_id     = data.vault_generic_secret.proxmox_credentials.data["terraform-token-id"]
  proxmox_api_token_secret = data.vault_generic_secret.proxmox_credentials.data["terraform-secret"]
  proxmox_api_url          = data.vault_generic_secret.proxmox_credentials.data["terraform-api-url"]
  ssh_pubkey               = data.vault_generic_secret.proxmox_credentials.data["id_rsa.pub"]
  default_password         = data.vault_generic_secret.proxmox_credentials.data["root-user-password"]

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
