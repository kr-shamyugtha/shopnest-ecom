# ============================================================================
# General Configuration
# ============================================================================

variable "location" {
  description = "Azure region for the state backend"
  type        = string
  default     = "germanywestcentral"
}

# ============================================================================
# Resource Group Configuration
# ============================================================================

variable "resource_group_name" {
  description = "Name of the resource group holding Terraform state resources"
  type        = string
  default     = "shopnest-tfstate-rg"
}

# ============================================================================
# Storage Account Configuration
# ============================================================================

variable "storage_account_name" {
  description = "Globally unique name for the storage account (lowercase letters/numbers only, no hyphens)"
  type        = string
}

variable "container_name" {
  description = "Name of the blob container that will hold the state file"
  type        = string
  default     = "tfstate"
}

variable "enable_versioning" {
  description = "Keep previous versions of the state file — lets you recover from a bad apply"
  type        = bool
  default     = true
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


variable "blob_delete_retention_days" {
  description = "Number of days deleted blob data is retained for recovery."
  type        = number
  default     = 30

  validation {
    condition     = var.blob_delete_retention_days >= 7 && var.blob_delete_retention_days <= 365
    error_message = "Blob delete retention must be between 7 and 365 days."
  }
}

variable "container_delete_retention_days" {
  description = "Number of days deleted containers are retained for recovery."
  type        = number
  default     = 30

  validation {
    condition     = var.container_delete_retention_days >= 7 && var.container_delete_retention_days <= 365
    error_message = "Container delete retention must be between 7 and 365 days."
  }
}