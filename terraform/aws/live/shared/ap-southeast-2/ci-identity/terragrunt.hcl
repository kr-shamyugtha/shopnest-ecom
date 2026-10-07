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
  source = "${get_repo_root()}/terraform/aws/modules//ci-oidc"
}

# No Azure counterpart unit: Azure DevOps auto-provisions the app
# registration and federated credential behind the sc-shopnest-azure service
# connection, so the Azure units just hardcode the resulting service
# principal's object ID as ci_principal_id. Nothing auto-provisions the AWS
# side, so the trust relationship is declared here and its role ARN flows
# into the ecr and eks units as a dependency instead of a pasted GUID.
inputs = {
  project_name = local.project_name
  region       = local.region

  # The repository GitHub Actions runs from. Only this repo, and only the
  # refs below, can assume the CI role.
  github_repository = "kr-shamyugtha/shopnest-ecom"

  # Branch refs only — deliberately no pull_request subject. This is the
  # trust-policy-level equivalent of the Azure pipeline's
  # `ne(variables['Build.Reason'], 'PullRequest')` conditions on the
  # PushToACR and DeployToAKS stages: an unmerged PR cannot push to the
  # shared registry or commit to the GitOps config, and unlike a stage
  # condition this guard survives someone editing the workflow file.
  allowed_git_refs = ["refs/heads/main"]

  role_name = "shopnest-ci"

  # Environments whose backend IRSA role the pipeline may read, so it can
  # write the ARN into the GitOps values file — the counterpart to
  # `az identity show` in ci/azure-pipelines.yml.
  workload_identity_environments = ["dev"]

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
