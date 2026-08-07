# ============================================================================
# General Configuration
# ============================================================================

variable "location" {
  description = "Azure region for the state backend"
  type        = string
  default     = "germanywestcentral"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name, used for naming and tagging resources"
  type        = string
  default     = "shopnest"
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
  default     = "shopnesttfstate001"
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
    ManagedBy   = "terraform"
    Environment = "dev"
    Purpose     = "terraform-state-backend"
  }
}