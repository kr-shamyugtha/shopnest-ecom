resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.project_name}-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.project_name}-${var.environment}-aks"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled    = true
  azure_policy_enabled      = true

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = var.admin_group_object_ids
  }

  default_node_pool {
    name           = "system"
    vm_size        = var.vm_size
    vnet_subnet_id = var.subnet_id

    auto_scaling_enabled = var.enable_auto_scaling
    node_count           = var.enable_auto_scaling ? null : var.node_count
    min_count            = var.enable_auto_scaling ? var.min_count : null
    max_count            = var.enable_auto_scaling ? var.max_count : null

    upgrade_settings {
      max_surge = var.upgrade_max_surge
    }
  }

  node_provisioning_profile {
    mode = "Manual"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    pod_cidr            = var.pod_cidr
    load_balancer_sku   = "standard"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  # oms_agent/monitor_metrics (Container Insights + Azure Managed
  # Prometheus) removed deliberately — measured at ~946m CPU requests
  # combined (ama-logs + ama-metrics daemonsets), a quarter of this
  # 2-node cluster's entire allocatable CPU, on a cluster that was
  # already at 99-100% CPU requests with no room for anything else.
  # Replaced by a self-hosted kube-prometheus-stack + Loki instead of
  # running both — also more portable (same stack works unchanged on
  # EKS later), not just a workaround for the capacity constraint.

  tags = var.tags
}

# ==========================================================
# CI/CD Pipeline Access (narrower than admin_group_object_ids)
# ==========================================================

resource "azurerm_role_assignment" "ci_aks_cluster_user" {
  count = var.ci_principal_id != null ? 1 : 0

  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = var.ci_principal_id
}

resource "azurerm_role_assignment" "ci_aks_rbac_writer" {
  count = var.ci_principal_id != null ? 1 : 0

  scope                = azurerm_kubernetes_cluster.this.id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = var.ci_principal_id
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                            = var.acr_id
  role_definition_name             = "AcrPull"
  principal_id                     = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
  skip_service_principal_aad_check = true
}

# ==========================================================
# Backend Workload Identity
#
# Delegated to the standalone workload-identity module rather than
# declared inline here. The cluster and the identities of the workloads
# running on it have different lifecycles, and keeping them in one module
# meant every new workload required an edit to this file — the wrong
# seam. A second workload now either adds another module block here or,
# better, gets its own Terragrunt unit depending on this cluster's
# oidc_issuer_url output, with no change to the aks module at all.
#
# The moved blocks below are what make this refactor safe: they tell
# Terraform these are the SAME three objects under new addresses, so they
# are relocated in state rather than destroyed and recreated. Recreating
# the identity would mint a new clientId, which would break the
# ServiceAccount annotation, the SecretProviderClass, and the Key Vault
# role assignment all at once.
# ==========================================================

module "backend_workload_identity" {
  source = "../workload-identity"

  project_name        = var.project_name
  environment         = var.environment
  workload_name       = "backend"
  location            = var.location
  resource_group_name = var.resource_group_name

  oidc_issuer_url      = azurerm_kubernetes_cluster.this.oidc_issuer_url
  namespace            = var.workload_namespace
  service_account_name = var.workload_service_account

  ci_principal_id = var.ci_principal_id
  tags            = var.tags
}

moved {
  from = azurerm_user_assigned_identity.backend
  to   = module.backend_workload_identity.azurerm_user_assigned_identity.this
}

moved {
  from = azurerm_federated_identity_credential.backend
  to   = module.backend_workload_identity.azurerm_federated_identity_credential.this
}

moved {
  from = azurerm_role_assignment.ci_backend_identity_reader
  to   = module.backend_workload_identity.azurerm_role_assignment.ci_reader
}
