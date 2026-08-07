resource "azurerm_container_registry" "this" {
  name                = "${var.project_name}acr"
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = false
  tags                = var.tags
}