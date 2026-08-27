# ============================================================================
# Terraform Backend Bootstrap - Azure
# ============================================================================
# Creates the Azure Storage Account + Blob Container used for
# Terraform remote state.
#
# This bootstrap is intentionally separate from the main infrastructure.
# It should be executed once for the Azure subscription.
# ============================================================================

provider "azurerm" {
  features {}

  storage_use_azuread = true
}

data "azurerm_client_config" "current" {}

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

  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  # Entra ID / OAuth only
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true
  local_user_enabled              = false

  blob_properties {
    versioning_enabled = var.enable_versioning

    delete_retention_policy {
      days = var.blob_delete_retention_days
    }

    container_delete_retention_policy {
      days = var.container_delete_retention_days
    }
  }

  tags = var.tags
}

# ============================================================================
# Bootstrap identity access
# ============================================================================
#
# The identity running this bootstrap needs Blob Data Contributor permission
# because Shared Key authentication is disabled.
#
# This is intentionally based on the currently authenticated Azure identity,
# not a hardcoded user.
# ============================================================================

resource "azurerm_role_assignment" "bootstrap_state_access" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_container" "state" {
  name                  = var.container_name
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"

  depends_on = [
    azurerm_role_assignment.bootstrap_state_access
  ]
}