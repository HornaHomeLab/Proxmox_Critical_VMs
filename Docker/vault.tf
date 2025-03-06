terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "3.25.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }
}
data "local_sensitive_file" "root_access_token" {
  filename = var.root_access_token_file
}

data "local_sensitive_file" "proxmox_user_pubkey" {
  filename = var.proxmox_user_pubkey_file
}
data "local_sensitive_file" "proxmox_user_privkey" {
  filename = var.proxmox_user_privkey_file
}
data "local_sensitive_file" "proxmox_user_password" {
  filename = var.proxmox_user_password_file
}

# Configure the Docker provider
provider "docker" {
  host = "ssh://proxmox@${var.docker_machine_ip}:22"
  ssh_opts = [
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-i", "${var.proxmox_user_privkey_file}"
  ]
}

# Configure the Vault provider
provider "vault" {
  address = "http://${var.docker_machine_ip}:8200"
  token   = data.local_sensitive_file.root_access_token.content
}

# Pull the Vault Docker image
resource "docker_image" "vault" {
  name         = "hashicorp/vault:1.19"
  keep_locally = true # Prevents Terraform from deleting the image
}

# Run the Vault container
resource "docker_container" "vault" {
  name         = "vault"
  image        = docker_image.vault.image_id
  network_mode = "bridge"
  ports {
    internal = 8200
    external = 8200
  }
  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=${data.local_sensitive_file.root_access_token.content}",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200"
  ]
  capabilities {
    add = ["IPC_LOCK"]
  }
  restart = "unless-stopped"
}

resource "vault_policy" "github_users_policy" {
  name = "github-users-policy"

  policy = <<EOT
# Allow read and list access to the vault_access_secrets KV engine
path "${vault_mount.vault_access_secrets.path}/*" {
  capabilities = ["read", "list"]
}

# Allow listing of the vault_access_secrets path
path "${vault_mount.vault_access_secrets.path}/" {
  capabilities = ["list"]
}

path "${vault_mount.service_accounts.path}/*" {
  capabilities = ["read", "list"]
}

# Allow listing of the vault_access_secrets path
path "${vault_mount.service_accounts.path}/" {
  capabilities = ["list"]
}

EOT
}
resource "vault_github_auth_backend" "github" {
  organization   = "HornaHomeLab"
  token_policies = [vault_policy.github_users_policy.name]
}

#Enable AppRole Authentication
resource "vault_auth_backend" "approle" {
  type = "approle"
  path = "approle"
}

resource "vault_approle_auth_backend_role" "automation_role" {
  backend        = vault_auth_backend.approle.path
  role_name      = "automation-role"
  token_policies = ["default"]
  token_ttl      = 3600
  token_max_ttl  = 86400
}

resource "vault_approle_auth_backend_role_secret_id" "automation_secret" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.automation_role.role_name
}

resource "vault_approle_auth_backend_role" "ansible_role" {
  backend        = vault_auth_backend.approle.path
  role_name      = "ansible-role"
  token_policies = ["default"]
  token_ttl      = 3600
  token_max_ttl  = 86400
}

resource "vault_approle_auth_backend_role_secret_id" "ansible_secret" {
  backend   = vault_auth_backend.approle.path
  role_name = vault_approle_auth_backend_role.ansible_role.role_name
}


resource "vault_mount" "vault_access_secrets" {
  type        = "kv"
  path        = "vault_access_secrets"
  description = "Secrets for accessing Vault"
}

resource "vault_kv_secret" "root_access_token" {
  path = "${vault_mount.vault_access_secrets.path}/root_access_token"
  data_json = jsonencode({
    auth_type    = "Token"
    access_token = data.local_sensitive_file.root_access_token.content
  })
}

resource "vault_kv_secret" "automation_roles" {
  path = "${vault_mount.vault_access_secrets.path}/default_automation_role"
  data_json = jsonencode({
    role_id   = vault_approle_auth_backend_role.automation_role.role_id
    secret_id = vault_approle_auth_backend_role_secret_id.automation_secret.secret_id
  })
}
resource "vault_kv_secret" "ansible_roles" {
  path = "${vault_mount.vault_access_secrets.path}/ansible_role"
  data_json = jsonencode({
    role_id   = vault_approle_auth_backend_role.ansible_role.role_id
    secret_id = vault_approle_auth_backend_role_secret_id.ansible_secret.secret_id
  })
}


resource "vault_mount" "service_accounts" {
  type        = "kv"
  path        = "service_accounts"
  description = "Service accounts credentials"
}

resource "vault_kv_secret" "proxmox_user" {
  path = "${vault_mount.service_accounts.path}/proxmox_user"
  data_json = jsonencode({
    username    = "proxmox"
    password = data.local_sensitive_file.proxmox_user_password.content
    private_key = data.local_sensitive_file.proxmox_user_privkey.content
    public_key  = data.local_sensitive_file.proxmox_user_pubkey.content
  })
}
