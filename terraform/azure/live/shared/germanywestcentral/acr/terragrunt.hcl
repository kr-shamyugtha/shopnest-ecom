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

dependency "ci_identity" {
  config_path = "../ci-identity"

  mock_outputs = {
    service_principal_object_id = "00000000-0000-0000-0000-000000000000"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  name                = "shopnestacr2026"
  location            = dependency.resource_group.outputs.location
  resource_group_name = dependency.resource_group.outputs.name
  # sc-shopnest-azure Azure DevOps service connection's OIDC identity, now
  # owned by the ci-identity module (imported from the app Azure DevOps
  # originally auto-provisioned — kavitography-shopnest-ado-34471a29-...).
  # Role assignments need the SERVICE PRINCIPAL object ID specifically, not
  # the Application object ID ("PrincipalTypeNotSupported" otherwise).
  ci_principal_id = dependency.ci_identity.outputs.service_principal_object_id

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
