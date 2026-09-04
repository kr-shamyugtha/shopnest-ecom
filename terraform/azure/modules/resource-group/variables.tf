variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_delete_lock" {
  description = "Apply a CanNotDelete Azure resource lock to this resource group (and, by inheritance, everything in it). Leave false for environments you expect to tear down (e.g. dev)."
  type        = bool
  default     = false
}