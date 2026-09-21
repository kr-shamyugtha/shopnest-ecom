include "root" {
  path = find_in_parent_folders()
}

locals {
  env_vars     = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  environment  = local.env_vars.locals.environment
  project_name = "shopnest"
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//ci-identity"
}

inputs = {
  # Real, live display name of the app Azure DevOps auto-provisioned for
  # sc-shopnest-azure — not something we get to rename without breaking the
  # active service connection tied to it.
  display_name = "kavitography-shopnest-ado-34471a29-d555-483d-be62-866bae025fd0"
}
