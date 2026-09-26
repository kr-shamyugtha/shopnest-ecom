variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  description = "Resource group the managed identity resource itself is created in."
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster Atlantis runs on."
  type        = string
}

variable "dev_resource_group_id" {
  description = "Resource ID of the dev resource group Atlantis is allowed to manage."
  type        = string
}

variable "tfstate_resource_group_id" {
  description = "Resource ID of the resource group holding the Terraform state storage account."
  type        = string
}

variable "aks_cluster_id" {
  description = "Resource ID of the AKS cluster, for the Cluster User / RBAC Writer grants the cert-manager and ingress-nginx units need."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
