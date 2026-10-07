variable "project_name" {
  type = string
}

variable "user_name" {
  type    = string
  default = "shopnest-ci"
}

variable "workload_identity_environments" {
  description = "Environments whose backend workload role the pipeline may read, to write its ARN into the GitOps values file."
  type        = list(string)
  default     = ["dev"]
}

variable "region" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
