# ============================================================================
# Terraform Backend Bootstrap - Azure
# ============================================================================
# Creates the Azure Storage account + container needed for Terraform remote
# state management. Azure Storage handles state locking natively (via blob
# lease) — no separate lock table needed, unlike AWS's S3+DynamoDB pattern.
#
# Run this FIRST, before any other Terraform in this project:
#   terraform init
#   terraform apply
#
# After this completes, copy the output values into terraform/azure/backend.tf
# ============================================================================

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "state" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_storage_account" "state" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = var.tags

  blob_properties {
    versioning_enabled = var.enable_versioning
  }
}

resource "azurerm_storage_container" "state" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}