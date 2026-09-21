variable "project_name" {
  description = "Project prefix used in resource names (e.g. shopnest)"
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names (e.g. dev, staging, prod)"
  type        = string
}

variable "workload_name" {
  description = <<-EOT
    Short name of the workload this identity belongs to (e.g. backend).
    Combined with project_name and environment to produce the identity
    name "<project>-<env>-<workload>-identity" and the federated
    credential name "<project>-<env>-<workload>-fic". Changing this
    renames — and therefore recreates — the identity, which issues a new
    clientId and breaks anything referencing the old one.
  EOT
  type        = string
}

variable "location" {
  description = "Azure region for the managed identity"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the managed identity is created in"
  type        = string
}

variable "oidc_issuer_url" {
  description = "OIDC issuer URL of the AKS cluster whose ServiceAccount tokens this identity will trust"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the ServiceAccount this identity is federated to"
  type        = string
}

variable "service_account_name" {
  description = "Name of the Kubernetes ServiceAccount this identity is federated to"
  type        = string
}

variable "ci_principal_id" {
  description = <<-EOT
    Object ID of the CI service principal to grant Reader on this
    identity, so a pipeline can resolve its clientId. Null (the default)
    skips the role assignment entirely.
  EOT
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the managed identity"
  type        = map(string)
  default     = {}
}
