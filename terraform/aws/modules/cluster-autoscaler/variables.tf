variable "chart_version" {
  description = "Must ship the autoscaler minor that matches the cluster's Kubernetes minor (9.59.0 = 1.35)."
  type        = string
  default     = "9.59.0"
}

variable "tags" {
  type    = map(string)
  default = {}
}
