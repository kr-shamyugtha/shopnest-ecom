# A stable identity AKS's kubelets use to pull from ACR, created once here
# rather than left to each cluster's own auto-generated kubelet identity.
#
# The problem this solves: shopnest-shared-rg (the ACR's resource group) has
# a CanNotDelete lock. A role assignment scoped to the ACR lives under that
# lock regardless of which identity holds it, so if the aks module grants
# AcrPull to the cluster's own auto-generated kubelet identity, every
# destroy of that cluster fails trying to delete that assignment out from
# under the lock — the assignment has to be pulled out of Terraform's state
# by hand before the destroy can proceed.
#
# Shared across every environment's cluster deliberately: they all pull
# from the same one ACR, so one identity, granted once, is simpler than a
# separate identity and grant per environment. A user-assigned identity can
# be attached to any number of clusters as their kubelet identity.
resource "azurerm_user_assigned_identity" "kubelet" {
  name                = "${var.project_name}-aks-kubelet-identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.kubelet.principal_id
}
