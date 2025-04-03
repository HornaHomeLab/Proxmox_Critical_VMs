variable "vault_role_id" {
  type        = string
  description = "Vault AppRole Role ID"
  sensitive   = true
}

variable "vault_secret_id" {
  type        = string
  description = "Vault AppRole Secret ID"
  sensitive   = true
}