include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_vars.locals.environment
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//acr"
}

dependency "resource_group" {
  config_path = "../resource-group"

  mock_outputs = {
    name     = "mock-rg"
    location = "germanywestcentral"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  name                = "shopnestacr2026"
  location            = dependency.resource_group.outputs.location
  resource_group_name = dependency.resource_group.outputs.name
  # sc-shopnest-azure Azure DevOps service connection's service principal
  ci_principal_id = "1ad45693-e0d5-4461-bc95-c274d62d2a46"

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
