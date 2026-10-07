variable "chart_version" {
  type    = string
  default = "4.11.3"
}

variable "internet_facing" {
  description = "Provision a public NLB. Set false for an internal-only cluster."
  type        = bool
  default     = true
}

variable "replica_count" {
  type    = number
  default = 1
}
