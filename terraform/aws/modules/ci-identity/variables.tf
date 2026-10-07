variable "project_name" {
  type = string
}

variable "github_repository" {
  description = "The repository allowed to assume the CI role, as \"owner/repo\"."
  type        = string
}

variable "allowed_git_refs" {
  description = "Git refs the CI role may be assumed from. Deliberately excludes pull_request contexts — see the comment in main.tf."
  type        = list(string)
  default     = ["refs/heads/main"]
}

variable "role_name" {
  type    = string
  default = "shopnest-ci"
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC provider. An AWS account can only have one per issuer URL, so set this false if another stack already created it."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "ARN of an already-existing GitHub OIDC provider, used when create_oidc_provider is false."
  type        = string
  default     = null
}

variable "workload_identity_environments" {
  description = "Environments whose backend IRSA role the pipeline may read, to write its ARN into the GitOps values file."
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
