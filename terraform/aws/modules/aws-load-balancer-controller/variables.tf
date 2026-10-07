variable "vpc_id" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer_host" {
  description = "Cluster OIDC issuer with the https:// scheme stripped."
  type        = string
}

variable "chart_version" {
  type    = string
  default = "1.9.2"
}

variable "replica_count" {
  type    = number
  default = 1
}

variable "tags" {
  type    = map(string)
  default = {}
}
