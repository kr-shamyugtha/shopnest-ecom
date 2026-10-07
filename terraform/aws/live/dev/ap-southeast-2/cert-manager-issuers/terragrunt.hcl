include "root" {
  path = find_in_parent_folders()
}

locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region      = local.region_vars.locals.region
}

terraform {
  source = "${get_repo_root()}/terraform/aws/modules//cert-manager-issuers"
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

# Ordering only, no outputs used — the ClusterIssuer CRD this unit's
# resources need has to already be live, which only cert-manager's own
# apply (not just its plan) guarantees. See cert-manager-issuers/main.tf.
# The ACME solver also needs ingress-nginx to answer the HTTP-01 challenge.
dependencies {
  paths = ["../cert-manager", "../ingress-nginx"]
}

inputs = {
  cluster_host            = dependency.eks.outputs.host
  cluster_ca_certificate  = dependency.eks.outputs.cluster_ca_certificate
  cluster_name            = dependency.eks.outputs.cluster_name
  region                  = local.region
  acme_registration_email = "kavitography@gmail.com"
}
