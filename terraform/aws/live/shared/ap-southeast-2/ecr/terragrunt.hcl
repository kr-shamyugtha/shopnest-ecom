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
  source = "${get_repo_root()}/terraform/aws/modules//ecr"
}

dependency "resource_group" {
  config_path = "../resource-group"
  mock_outputs = {
    name   = "mock-rg"
    region = "ap-southeast-2"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "ci_identity" {
  config_path = "../ci-identity"
  mock_outputs = {
    user_name     = "mock-ci-user"
    principal_arn = "arn:aws:iam::000000000000:user/mock-ci-user"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  namespace           = local.project_name
  region              = dependency.resource_group.outputs.region
  resource_group_name = dependency.resource_group.outputs.name

  repositories = ["shopnest-backend", "shopnest-frontend"]

  # Counterpart to the Azure unit's ci_principal_id, resolved from the
  # ci-identity unit rather than pasted in as a GUID.
  ci_user_name = dependency.ci_identity.outputs.user_name

  # Deliberately empty. ECR needs a repository policy only for
  # cross-account pulls; the clusters live in this same account and pull via
  # AmazonEC2ContainerRegistryReadOnly on their node role (granted in the
  # eks module). Listing the node roles here instead would invert the
  # dependency — ECR would have to wait for all three clusters, while the
  # pipeline needs the registry to exist long before any cluster does.
  pull_principal_arns = []

  # ACR's Basic SKU caps total storage; ECR bills per GB with no ceiling,
  # so retention has to be explicit or the repositories grow forever.
  untagged_image_retention_days = 7
  tagged_image_retention_count  = 30

  # Every consumer of these images pins an exact tag (the GitOps values
  # files, the Argo CD application). Immutable tags make that pin mean
  # something — a tag can never be repointed at different content.
  image_tag_mutability = "IMMUTABLE"

  enable_delete_lock = true

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
