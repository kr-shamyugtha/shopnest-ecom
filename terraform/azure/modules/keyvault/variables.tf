variable "environment" {
  description = "Deployment environment"
  type        = string
}
variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "backend_identity_object_id" {
  description = "Object ID of the backend workload identity that reads secrets via the Secrets Store CSI driver"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
}

variable "enable_delete_lock" {
  description = "Apply a CanNotDelete Azure resource lock to this Key Vault. Leave false for environments you expect to tear down (e.g. dev)."
  type        = bool
  default     = false
}

variable "admin_object_id" {
  description = <<-EOT
    Object ID of the principal granted Key Vault Secrets Officer (full
    create/update/delete on secrets). Prefer an Entra group over an
    individual user, so changing who can manage secrets is a membership
    change rather than a Terraform run.

    Deliberately required with no default: an implicit fallback to
    data.azurerm_client_config.current.object_id is what this variable
    exists to remove — it silently handed full secret access to whatever
    identity ran `terraform apply`, including CI.
  EOT
  type        = string
}
