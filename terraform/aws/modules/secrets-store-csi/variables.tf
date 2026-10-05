variable "driver_chart_version" {
  type    = string
  default = "1.4.6"
}

variable "aws_provider_chart_version" {
  type    = string
  default = "0.3.11"
}

variable "rotation_poll_interval" {
  description = "How often the driver re-reads Secrets Manager for changed values."
  type        = string
  default     = "2m"
}
