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
    location = "germanywestcentral"
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

dependency "acr" {
  config_path = "../acr"
  mock_outputs = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/mock/acr"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name         = local.project_name
  environment         = local.environment
  location             = dependency.resource_group.outputs.location
  resource_group_name  = dependency.resource_group.outputs.name
  subnet_id            = dependency.networking.outputs.aks_subnet_id
  acr_id = dependency.acr.outputs.id
  node_count           = 2
  vm_size              = "Standard_D2s_v7"
  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
