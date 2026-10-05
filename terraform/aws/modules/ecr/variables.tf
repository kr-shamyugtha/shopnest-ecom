variable "namespace" {
  description = "Repository name prefix, e.g. \"shopnest\" produces shopnest/shopnest-backend."
  type        = string
}

variable "repositories" {
  description = "Image names to create repositories for."
  type        = list(string)
  default     = ["shopnest-backend", "shopnest-frontend"]
}

variable "region" {
  type = string
}

variable "resource_group_name" {
  description = "Name of the environment's AWS Resource Group. Carried through only so the live/ units keep the same shape as terraform/azure/live."
  type        = string
}

variable "image_tag_mutability" {
  description = "IMMUTABLE stops a tag ever being repointed at different content, which is what makes a GitOps image tag a real pin. MUTABLE only if something genuinely needs to overwrite a tag."
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be MUTABLE or IMMUTABLE."
  }
}

variable "untagged_image_retention_days" {
  type    = number
  default = 7
}

variable "tagged_image_retention_count" {
  type    = number
  default = 30
}

variable "pull_principal_arns" {
  description = "IAM role ARNs (the environments' EKS node roles) allowed to pull these images. Empty leaves the repositories with no resource policy, i.e. same-account IAM only."
  type        = list(string)
  default     = []
}

variable "ci_role_name" {
  description = "Name of the CI/CD pipeline's IAM role, granted push access. Null skips the grant. Counterpart to the Azure module's ci_principal_id."
  type        = string
  default     = null
}

variable "enable_delete_lock" {
  description = "Refuse to destroy a repository that still contains images. Counterpart to the CanNotDelete lock the Azure side puts on the shared resource group."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
