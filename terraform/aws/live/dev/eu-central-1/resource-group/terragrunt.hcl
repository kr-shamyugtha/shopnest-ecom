include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars  = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  environment  = local.env_vars.locals.environment
  region       = local.region_vars.locals.region
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/aws/modules//resource-group"
}

inputs = {
  name               = "${local.project_name}-${local.environment}-rg"
  region             = local.region
  enable_delete_lock = false

  grouping_tags = {
    Project     = local.project_name
    Environment = local.environment
  }

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
