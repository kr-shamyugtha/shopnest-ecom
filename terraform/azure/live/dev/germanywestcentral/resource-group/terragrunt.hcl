include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment  = local.env_vars.locals.environment
  location     = local.region_vars.locals.location
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//resource-group"
}

inputs = {
  name     = "${local.project_name}-${local.environment}-rg"
  location = local.location
  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
