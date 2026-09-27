include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_vars.locals.environment
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//aks"
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name     = "mock-rg"
    location = "westeurope"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    aks_subnet_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.Network/virtualNetworks/mock-vnet/subnets/mock-aks-subnet"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

# Shared across all environments and has its own independent lifecycle —
# see terraform/azure/modules/kubelet-identity for why this exists instead
# of letting each cluster auto-generate its own kubelet identity.
dependency "kubelet_identity" {
  config_path = "../../../shared/germanywestcentral/kubelet-identity"
  mock_outputs = {
    id                            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock-kubelet-identity"
    client_id                     = "00000000-0000-0000-0000-000000000000"
    principal_id                  = "00000000-0000-0000-0000-000000000000"
    cluster_identity_id           = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/mock-cluster-identity"
    cluster_identity_principal_id = "00000000-0000-0000-0000-000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name               = local.project_name
  environment                = local.environment
  location                   = dependency.resource_group.outputs.location
  resource_group_name        = dependency.resource_group.outputs.name
  subnet_id                  = dependency.networking.outputs.aks_subnet_id
  kubelet_identity_id        = dependency.kubelet_identity.outputs.id
  kubelet_identity_client_id = dependency.kubelet_identity.outputs.client_id
  kubelet_identity_object_id = dependency.kubelet_identity.outputs.principal_id
  cluster_identity_id        = dependency.kubelet_identity.outputs.cluster_identity_id
  # Old tenant's "shopnest-aks-admins" group — deleted along with the old
  # tenant in the trial migration. Updated to the same group's new-tenant
  # object ID (dev uses this too; only prod has its own dedicated group).
  admin_group_object_ids = [
    "190544d6-0159-4194-aefe-10600507b1e4"
  ]
  enable_auto_scaling = true
  min_count           = 2
  max_count           = 2
  vm_size             = "Standard_D2s_v6"
  kubernetes_version  = "1.35"
  sku_tier            = "Standard"

  # 2 nodes already uses the full 4 vCPU regional quota in westeurope. Azure
  # rejects max_surge=0 (it requires max_unavailable to be non-zero in that
  # case, which this provider version can't set), so upgrades default to
  # max_surge=1 and will need a temporary 3rd node (6 vCPU) — exceeding
  # quota. Scale down to 1 node before running a Kubernetes version upgrade,
  # or request a quota increase first. See INFRASTRUCTURE_CHECKLIST.md.
  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
