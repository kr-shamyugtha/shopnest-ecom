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
  source = "${get_repo_root()}/terraform/aws/modules//argocd"
}

dependency "eks" {
  config_path = "../eks"
  mock_outputs = {
    host                   = "https://mock.example.com"
    cluster_ca_certificate = "bW9jaw=="
    cluster_name           = "mock-cluster"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

# Ordering only. Argo CD's Applications need: the app secrets' CSI driver
# and IAM grants (the backend pod mounts them), ingress-nginx and the
# issuers (the Ingresses), and the EBS-backed storage the monitoring PVCs
# bind to (eks).
dependencies {
  paths = [
    "../secrets-manager",
    "../secrets-store-csi",
    "../ingress-nginx",
    "../cert-manager-issuers",
    "../metrics-server",
  ]
}

inputs = {
  cluster_host           = dependency.eks.outputs.host
  cluster_ca_certificate = dependency.eks.outputs.cluster_ca_certificate
  cluster_name           = dependency.eks.outputs.cluster_name
  region                 = local.region

  project_name = local.project_name
  environment  = local.environment

  # Read straight from the files in the repo, so there is exactly one copy
  # of this config — same arrangement as the Azure unit.
  install_values = file("${get_repo_root()}/argocd/install-values-aws.yaml")
  apps_values = [
    file("${get_repo_root()}/argocd/values-aws.yaml"),
    file("${get_repo_root()}/argocd/values-monitoring-aws.yaml"),
  ]

  tags = {
    ManagedBy   = "terraform"
    Environment = local.environment
    Project     = local.project_name
  }
}
