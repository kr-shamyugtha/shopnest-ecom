variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "install_values" {
  description = "Contents of argocd/install-values-aws.yaml, passed through as-is."
  type        = string
}

variable "apps_values" {
  description = "Contents of argocd/values-aws.yaml and argocd/values-monitoring-aws.yaml, in that order — passed to argocd-apps the same way `-f` twice would be."
  type        = list(string)
}

# Same chart versions as the Azure module.
variable "argocd_chart_version" {
  type    = string
  default = "10.9.2"
}

variable "argocd_apps_chart_version" {
  type    = string
  default = "2.0.5"
}

variable "tags" {
  type    = map(string)
  default = {}
}
