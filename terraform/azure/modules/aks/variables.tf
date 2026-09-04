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

variable "enable_auto_scaling" {
  type    = bool
  default = false
}

variable "min_count" {
  type    = number
  default = null
}

variable "max_count" {
  type    = number
  default = null
}

variable "vm_size" {
  type    = string
  default = "Standard_D2s_v7"
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "pod_cidr" {
  description = "Virtual pod address space for Azure CNI Overlay. Doesn't need to be unique across environments or avoid the VNet CIDR the way vnet_cidr does."
  type        = string
  default     = "192.168.0.0/16"
}

variable "workload_namespace" {
  type    = string
  default = "shopnest"
}

variable "workload_service_account" {
  type    = string
  default = "shopnest-backend"
}

variable "sku_tier" {
  description = "AKS control plane SKU tier (Free has no SLA; Standard adds a financially-backed API server SLA)"
  type        = string
  default     = "Free"
}

variable "upgrade_max_surge" {
  description = "Node pool upgrade surge setting. \"1\" adds a temporary extra node during upgrades (needs quota headroom); \"0\" upgrades in place instead."
  type        = string
  default     = "1"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "ci_principal_id" {
  description = "Object ID of the CI/CD pipeline's service principal, granted just enough access to fetch credentials and deploy workloads (not cluster-admin). Null skips the grant."
  type        = string
  default     = null
}

variable "admin_group_object_ids" {
  description = "Microsoft Entra ID group object IDs with AKS administrator access."
  type        = list(string)

  validation {
    condition     = length(var.admin_group_object_ids) > 0
    error_message = "At least one Microsoft Entra admin group must be configured."
  }
}