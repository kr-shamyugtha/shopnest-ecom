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

variable "subnet_id" {
  type = string
}

variable "acr_id" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "node_count" {
  type    = number
  default = 1
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v7"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "admin_group_object_ids" {
  description = "Microsoft Entra ID group object IDs with AKS administrator access."
  type        = list(string)

  validation {
    condition     = length(var.admin_group_object_ids) > 0
    error_message = "At least one Microsoft Entra admin group must be configured."
  }
}