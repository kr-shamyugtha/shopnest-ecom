data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                       = var.key_vault_name
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
  principal_id         = var.backend_identity_object_id
}

# Secret MANAGEMENT (create/update/delete) — deliberately separated from the
# read-only grant above, and deliberately NOT bound to whoever happens to be
# running Terraform.
#
# This was previously data.azurerm_client_config.current.object_id, which
# silently granted full secret CRUD to the identity executing `apply`. That is
# an escalation path: the moment CI (or Atlantis) runs this module, the
# pipeline's service principal would gain read/write on every secret in the
# vault without that ever appearing in a diff. Naming the principal explicitly
# means the set of people who can manage secrets is reviewable in code.
#
# Granted to a GROUP rather than a person, matching how the AKS cluster's
# admin access is already handled (admin_group_object_ids) — membership
# changes then don't require a Terraform run.
resource "azurerm_role_assignment" "admin_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.admin_object_id
}

moved {
  from = azurerm_role_assignment.self_secrets_officer
  to   = azurerm_role_assignment.admin_secrets_officer
}

resource "azurerm_management_lock" "this" {
  count = var.enable_delete_lock ? 1 : 0

  name       = "${azurerm_key_vault.this.name}-delete-lock"
  scope      = azurerm_key_vault.this.id
  lock_level = "CanNotDelete"
  notes      = "Managed by Terraform - prevents accidental deletion of this Key Vault"
}