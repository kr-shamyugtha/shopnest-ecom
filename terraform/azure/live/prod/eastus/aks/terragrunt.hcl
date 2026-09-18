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
    location = "eastus"
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

# ACR is shared across all environments and has its own independent lifecycle.
dependency "acr" {
  config_path = "../../../shared/germanywestcentral/acr"
  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/mock/acr"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name                = local.project_name
  environment                 = local.environment
  location                    = dependency.resource_group.outputs.location
  resource_group_name         = dependency.resource_group.outputs.name
  subnet_id                   = dependency.networking.outputs.aks_subnet_id
  acr_id                      = dependency.acr.outputs.id
  admin_group_object_ids = [
    "91f40ba8-7d31-44c8-a2f2-371aa2b61e31" # shopnest-aks-admins-prod
  ]
  enable_auto_scaling = true
  min_count           = 2
  max_count           = 2
  vm_size             = "Standard_D2s_v7"
  kubernetes_version  = "1.35"
  sku_tier            = "Standard"

  # 2 nodes already uses the full 4 vCPU regional quota in eastus. Azure
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
