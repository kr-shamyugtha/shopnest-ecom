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
  source = "${get_repo_root()}/terraform/aws/modules//aws-load-balancer-controller"
}

dependency "networking" {
  config_path = "../networking"
  mock_outputs = {
    vpc_id = "vpc-mock"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    host                   = "https://mock.example.com"
    cluster_ca_certificate = "bW9jaw=="
    cluster_name           = "mock-cluster"
    oidc_provider_arn      = "arn:aws:iam::000000000000:oidc-provider/mock"
    oidc_issuer_host       = "oidc.eks.us-east-1.amazonaws.com/id/MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  cluster_host           = dependency.eks.outputs.host
  cluster_ca_certificate = dependency.eks.outputs.cluster_ca_certificate
  cluster_name           = dependency.eks.outputs.cluster_name
  region                 = local.region

  vpc_id            = dependency.networking.outputs.vpc_id
  oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
  oidc_issuer_host  = dependency.eks.outputs.oidc_issuer_host

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
