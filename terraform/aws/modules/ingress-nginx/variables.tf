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

variable "public_subnet_ids" {
  description = "Public subnets the internet-facing NLB is placed in, one Elastic IP each."
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
