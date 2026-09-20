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
  # sc-shopnest-azure Azure DevOps service connection's actual OIDC identity:
  # the SERVICE PRINCIPAL (not the Application object — a different Graph
  # object with a different object ID; role assignments reject Application
  # IDs with "PrincipalTypeNotSupported") for the app Azure DevOps
  # auto-provisioned for workload-identity federation
  # (kavitography-shopnest-ado-34471a29-...), NOT the manually created
  # "shopnest-ci" app, which has no federated credential and can't be used
  # by the service connection at all.
  ci_principal_id = "c4a166f3-2c4d-4bce-9e4e-0880dc154ba5"

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
