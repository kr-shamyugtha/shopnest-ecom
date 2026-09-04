resource "azurerm_virtual_network" "this" {
  name = "${var.project_name}-${var.environment}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet" "aks" {
  name = "${var.project_name}-${var.environment}-aks-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.aks_subnet_cidr]
}

resource "azurerm_network_security_group" "aks" {
  name                = "${var.project_name}-${var.environment}-aks-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Explicit deny, not just Azure's invisible built-in DenyAllInBound default —
# this makes the inbound posture a reviewable line in a `plan` diff instead of
# an assumption. AKS auto-injects its own (higher-precedence, lower-priority)
# rules on this NSG for any LoadBalancer Service you create later, so this
# doesn't block legitimate future ingress.
resource "azurerm_network_security_rule" "deny_internet_inbound" {
  name                        = "DenyInternetInbound"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.aks.name
}

# Outbound stays on Azure's default (AllowVnetOutBound + AllowInternetOutBound)
# rather than a service-tag allow-list. Tested against dev and confirmed this
# breaks real AKS functionality: nodes reported EgressBlocked against
# packages.microsoft.com, acs-mirror.azureedge.net, and packages.aks.azure.com
# — documented AKS node-health/bootstrap endpoints that Microsoft's own
# guidance says cannot be covered by service tags at all, only by FQDN-based
# rules on Azure Firewall. A plain NSG structurally can't do FQDN matching, so
# a tag-based allow-list here is always going to have gaps like this one —
# don't re-add outbound restriction without Azure Firewall in front of it.