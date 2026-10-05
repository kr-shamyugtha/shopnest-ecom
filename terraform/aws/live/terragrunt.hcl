locals {
  project_name = "shopnest"

  # Unlike Azure (where location is a per-resource argument), the AWS
  # provider is region-scoped — so the region has to be resolved here, at
  # include time, to generate a correctly-targeted provider for each unit.
  # find_in_parent_folders() resolves relative to the *including* unit, so
  # every live/<env>/<region>/<unit> picks up its own region.hcl.
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  region      = local.region_vars.locals.region
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    bucket  = "shopnest-tfstate-2026"
    key     = "${path_relative_to_include()}.tfstate"
    region  = "eu-central-1"
    encrypt = true

    # S3 native conditional-write locking, the counterpart to the blob
    # leases the azurerm backend uses. No DynamoDB table to keep in sync.
    use_lockfile = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<PROVIDER
provider "aws" {
  region = "${local.region}"
}
PROVIDER
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite"
  contents  = <<VERSIONS
terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    # helm/kubernetes are only actually used by the in-cluster add-on units
    # (ingress-nginx, cert-manager, secrets-store-csi, metrics-server,
    # cluster-autoscaler, aws-load-balancer-controller), but a module can
    # only have one required_providers block, and Terragrunt won't let a
    # child unit override this shared, generated one — so they're declared
    # here for every unit. Harmless for the modules that don't use them
    # (just an unused provider requirement). Same arrangement as the Azure
    # root config, deliberately.
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    # Only the eks unit uses this (to read the OIDC issuer's certificate and
    # derive its thumbprint), but the same one-required_providers-block rule
    # applies, so it is declared for every unit here.
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}
VERSIONS
}

inputs = {
  project_name = local.project_name
}
