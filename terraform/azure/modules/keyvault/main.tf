data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name = var.key_vault_name
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = true
  soft_delete_retention_days = 7
  tags                       = var.tags

  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "backend_secrets_reader" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id          = var.backend_identity_object_id
}

resource "azurerm_role_assignment" "self_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id          = data.azurerm_client_config.current.object_id
}

resource "azurerm_management_lock" "this" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "${azurerm_key_vault.this.name}-delete-lock"
  scope      = azurerm_key_vault.this.id
  lock_level = "CanNotDelete"
  notes      = "Managed by Terraform - prevents accidental deletion of this Key Vault"
}