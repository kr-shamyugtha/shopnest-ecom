variable "name" {
  type = string
}

variable "region" {
  description = "AWS region this environment lives in. Passed down to every unit in the environment, mirroring the Azure resource group's location output."
  type        = string
}

variable "grouping_tags" {
  description = "Tags a resource must carry to be considered part of this group."
  type        = map(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_delete_lock" {
  description = "Signals that this environment is protected from teardown. AWS has no resource-group-wide lock, so this flag is passed to the individual modules that do support deletion protection (ecr, eks, secrets-manager) rather than being enforced here. Leave false for environments you expect to tear down (e.g. dev)."
  type        = bool
  default     = false
}
