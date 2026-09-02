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