include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_vars.locals.environment
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/aws/modules//networking"
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name   = "mock-rg"
    region = "eu-west-1"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  project_name        = local.project_name
  environment         = local.environment
  region              = dependency.resource_group.outputs.region
  resource_group_name = dependency.resource_group.outputs.name

  vpc_cidr           = "10.120.0.0/16"
  az_count           = 3
  single_nat_gateway = false

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
