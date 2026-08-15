data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = "${var.project_name}-kv"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
  tags                       = var.tags

  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "aks_secrets_reader" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id          = var.aks_kubelet_identity_object_id
}

resource "azurerm_role_assignment" "self_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id          = data.azurerm_client_config.current.object_id
}