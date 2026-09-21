# ==========================================================
# Azure AD Workload Identity for a single Kubernetes workload.
#
# Extracted from the aks module so that adding a second workload no
# longer means editing the cluster's own module — the cluster and the
# identities that run on it are different concerns with different
# lifecycles. A new workload instantiates this module (either from a
# caller like aks, or as its own Terragrunt unit depending on the
# cluster's oidc_issuer_url output) instead of growing aks/main.tf.
#
# The chain this builds, and why each piece exists:
#
#   1. A user-assigned managed identity — the Azure-side principal that
#      role assignments (Key Vault Secrets User, etc.) are granted to.
#   2. A federated identity credential binding that Azure identity to
#      ONE specific Kubernetes ServiceAccount on ONE specific cluster.
#      The subject is "system:serviceaccount:<namespace>:<name>" — both
#      halves are load-bearing. Change the namespace or the service
#      account name and the token exchange stops matching, the pod can
#      no longer authenticate, and Key Vault reads fail.
#   3. Optionally, a Reader grant for CI so a pipeline can look up this
#      identity's clientId (az identity show) without holding broader
#      permissions.
#
# No secret material is created or read here — the identity is a
# principal, not a credential. Nothing in this module writes a secret
# value into Terraform state.
# ==========================================================

resource "azurerm_user_assigned_identity" "this" {
  name                = "${var.project_name}-${var.environment}-${var.workload_name}-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_federated_identity_credential" "this" {
  name = "${var.project_name}-${var.environment}-${var.workload_name}-fic"

  user_assigned_identity_id = azurerm_user_assigned_identity.this.id

  audience = [
    "api://AzureADTokenExchange"
  ]

  # The cluster's OIDC issuer — passed in rather than looked up, so this
  # module stays usable against any cluster without taking a dependency
  # on the aks module's internals.
  issuer  = var.oidc_issuer_url
  subject = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}

# CI needs to read this identity's clientId (az identity show) to write it
# into the GitOps config — scoped to just this one identity, not the whole
# resource group, since that's all it actually needs.
resource "azurerm_role_assignment" "ci_reader" {
  count = var.ci_principal_id != null ? 1 : 0

  scope                = azurerm_user_assigned_identity.this.id
  role_definition_name = "Reader"
  principal_id         = var.ci_principal_id
}
