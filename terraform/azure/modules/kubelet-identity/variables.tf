variable "project_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "acr_id" {
  description = "Resource ID of the shared ACR to grant this identity AcrPull on."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
