# ============================================================================
# General Configuration
# ============================================================================

variable "region" {
  description = "AWS region for the state backend. Mirrors the Azure backend living in germanywestcentral."
  type        = string
  default     = "eu-central-1"
}

# ============================================================================
# State Bucket Configuration
# ============================================================================

variable "state_bucket_name" {
  description = "Globally unique S3 bucket name holding Terraform state (lowercase letters, numbers and hyphens)"
  type        = string
}

variable "enable_versioning" {
  description = "Keep previous versions of the state file — lets you recover from a bad apply"
  type        = bool
  default     = true
}

variable "state_version_retention_days" {
  description = "Number of days superseded state versions are retained for recovery."
  type        = number
  default     = 30

  validation {
    condition     = var.state_version_retention_days >= 7 && var.state_version_retention_days <= 365
    error_message = "State version retention must be between 7 and 365 days."
  }
}

# ============================================================================
# Tagging
# ============================================================================

variable "tags" {
  description = "Tags applied to all resources in this module"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Purpose   = "terraform-state-backend"
  }
}
