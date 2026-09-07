variable "cluster_host" {
  description = "AKS API server endpoint"
  type        = string
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "AKS cluster CA certificate (base64)"
  type        = string
  sensitive   = true
}

variable "aks_aad_server_app_id" {
  description = "Well-known Azure Kubernetes Service AAD Server application ID (public cloud), used by kubelogin for token exec auth"
  type        = string
  default     = "6dae42f8-4368-4678-94ff-3960e28e3630"
}

variable "chart_version" {
  type    = string
  default = "4.11.3"
}
