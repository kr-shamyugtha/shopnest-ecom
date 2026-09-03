variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku" {
  type    = string
  default = "Basic"
}

variable "tags" {
  type    = map(string)
  default = {}
}
variable "name" {
  description = "Globally unique Azure Container Registry name"
  type        = string
}

variable "ci_principal_id" {
  description = "Object ID of the CI/CD pipeline's service principal, granted push access. Null skips the grant."
  type        = string
  default     = null
}
