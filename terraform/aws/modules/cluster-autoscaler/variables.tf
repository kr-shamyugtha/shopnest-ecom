variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer_host" {
  description = "Cluster OIDC issuer with the https:// scheme stripped."
  type        = string
}

variable "chart_version" {
  type    = string
  default = "9.43.2"
}

variable "tags" {
  type    = map(string)
  default = {}
}
