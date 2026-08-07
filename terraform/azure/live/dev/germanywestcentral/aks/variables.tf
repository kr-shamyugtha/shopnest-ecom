variable "project_name" {
  type    = string
  default = "shopnest"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "node_count" {
  type    = number
  default = 1
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}