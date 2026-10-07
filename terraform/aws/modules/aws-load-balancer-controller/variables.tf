variable "vpc_id" {
  type = string
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
