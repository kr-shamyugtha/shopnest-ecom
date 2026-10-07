include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_vars.locals.environment
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/aws/modules//secrets-manager"
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name   = "mock-rg"
    region = "eu-central-1"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    backend_identity_role_name = "mock-backend-role"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name        = local.project_name
  environment         = local.environment
  region              = dependency.resource_group.outputs.region
  resource_group_name = dependency.resource_group.outputs.name

  # Counterpart to key_vault_name. Secrets Manager has no vault object, so
  # the "vault" is the path prefix shopnest/${local.environment}/ that the
  # module builds from these two values.
  backend_identity_role_name = dependency.eks.outputs.backend_identity_role_name

  enable_delete_lock = false

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
