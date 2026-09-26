# Wraps the generic workload-identity module with the extra role
# assignments Atlantis specifically needs to actually run `terragrunt
# plan`/`apply` against dev — not just authenticate.
#
# Scoped to dev only, deliberately: a single Atlantis pod can hold exactly
# one federated identity (Azure Workload Identity ties one Azure identity to
# one Kubernetes ServiceAccount), so "one identity per environment" isn't
# achievable with one Atlantis instance. Staging/prod are still empty,
# never-applied environments (nothing to protect there yet) — extend this
# properly, with a separate Atlantis instance per environment, if and when
# they're actually used.
module "identity" {
  source = "../workload-identity"

  project_name        = var.project_name
  environment         = var.environment
  workload_name       = "atlantis"
  location            = var.location
  resource_group_name = var.resource_group_name

  oidc_issuer_url      = var.oidc_issuer_url
  namespace            = "atlantis"
  service_account_name = "atlantis"

  tags = var.tags
}

# Lets Atlantis create/modify/destroy the actual resources its Terragrunt
# units manage (networking, aks, keyvault) — scoped to just the dev
# resource group, never the subscription or another environment's RG.
resource "azurerm_role_assignment" "dev_rg_contributor" {
  scope                = var.dev_resource_group_id
  role_definition_name = "Contributor"
  principal_id         = module.identity.principal_id
}

# The azurerm backend uses Azure AD auth (use_azuread_auth = true in the
# root terragrunt.hcl), not a storage account key — so reading/writing
# state needs this explicitly, Contributor on the resource group alone
# doesn't cover data-plane blob access.
resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  scope                = var.tfstate_resource_group_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.identity.principal_id
}

# The cert-manager and ingress-nginx Terragrunt units authenticate to the
# cluster itself via kubelogin (see their helm-provider.tf), so Atlantis
# needs both: permission to fetch a token for the cluster, and RBAC inside
# it to actually manage the Helm releases those units create.
resource "azurerm_role_assignment" "aks_cluster_user" {
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = module.identity.principal_id
}

resource "azurerm_role_assignment" "aks_rbac_writer" {
  scope                = var.aks_cluster_id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = module.identity.principal_id
}
