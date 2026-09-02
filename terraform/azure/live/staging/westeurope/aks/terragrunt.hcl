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

# ACR is shared across all environments and has its own independent lifecycle.
dependency "acr" {
  config_path = "../../../shared/germanywestcentral/acr"
  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/mock/acr"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "monitoring" {
  config_path = "../monitoring"
  mock_outputs = {
    workspace_id = "/subscriptions/00000000-0000-0000-0000-000000000000/mock/law"
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
  log_analytics_workspace_id  = dependency.monitoring.outputs.workspace_id
  admin_group_object_ids = [
    "bb200924-909c-46ff-9ae7-a282264ccc6a"
  ]
  node_count = 1
  vm_size    = "Standard_D2s_v7"
  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
