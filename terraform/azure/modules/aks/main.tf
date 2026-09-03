resource "azurerm_kubernetes_cluster" "this" {
  name = "${var.project_name}-${var.environment}-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix = "${var.project_name}-${var.environment}-aks"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  oidc_issuer_enabled       = true
  workload_identity_enabled = true
  local_account_disabled = true
  azure_policy_enabled      = true

  azure_active_directory_role_based_access_control {
  azure_rbac_enabled    = true
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
  network_plugin    = "azure"
  network_policy    = "azure"
  load_balancer_sku = "standard"
}

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  monitor_metrics {}

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
# ==========================================================

resource "azurerm_user_assigned_identity" "backend" {
  name                = "${var.project_name}-${var.environment}-backend-identity"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_federated_identity_credential" "backend" {
  name = "${var.project_name}-${var.environment}-backend-fic"

  user_assigned_identity_id = azurerm_user_assigned_identity.backend.id

  audience = [
    "api://AzureADTokenExchange"
  ]

  issuer  = azurerm_kubernetes_cluster.this.oidc_issuer_url
  subject = "system:serviceaccount:${var.workload_namespace}:${var.workload_service_account}"
}