include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_vars.locals.environment
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//keyvault"
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name     = "mock-rg"
    location = "germanywestcentral"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "aks" {
  config_path = "../aks"
  mock_outputs = {
    backend_identity_object_id = "00000000-0000-0000-0000-000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name                = local.project_name
  environment                 = local.environment
  location                    = dependency.resource_group.outputs.location
  resource_group_name         = dependency.resource_group.outputs.name
  backend_identity_object_id  = dependency.aks.outputs.backend_identity_object_id
  key_vault_name = "shopnest-dev-kv2026"
  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
