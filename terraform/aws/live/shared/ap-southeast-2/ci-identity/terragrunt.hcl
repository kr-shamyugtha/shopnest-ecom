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
  source = "${get_repo_root()}/terraform/aws/modules//ci-identity"
}

# Counterpart to terraform/azure/live/shared/*/ci-identity. A GitHub OIDC
# role would be the first choice, but the AWS Free plan denies creating the
# OIDC provider it needs, so this is an IAM user with a narrow policy (see
# the module). Its ARN flows into the ecr and eks units as a dependency.
inputs = {
  project_name = local.project_name
  region       = local.region

  user_name = "shopnest-ci"

  # Environments whose backend workload role the pipeline may read, so it
  # can write the ARN into the GitOps values file — the counterpart to
  # `az identity show` in ci/azure-pipelines.yml.
  workload_identity_environments = ["dev"]

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
