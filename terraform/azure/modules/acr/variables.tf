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
