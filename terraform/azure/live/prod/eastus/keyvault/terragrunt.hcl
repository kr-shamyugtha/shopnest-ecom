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
    location = "eastus"
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

  # shopnest-aks-admins — the same Entra group that holds AKS admin access
  # (see the aks unit's admin_group_object_ids). Secret management is granted
  # to this group, never to whoever happens to run Terraform.
  admin_object_id = "190544d6-0159-4194-aefe-10600507b1e4"
  key_vault_name              = "shopnest-prod-kv"
  enable_delete_lock          = true
  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
