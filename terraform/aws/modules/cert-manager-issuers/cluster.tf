variable "cluster_host" {
  description = "EKS API server endpoint"
  type        = string
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "EKS cluster CA certificate (base64)"
  type        = string
  sensitive   = true
}

variable "cluster_name" {
  description = "EKS cluster name, used by `aws eks get-token` for exec auth"
  type        = string
}

variable "region" {
  type = string
}
