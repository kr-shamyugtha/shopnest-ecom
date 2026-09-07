# Present here purely so the IDE / a direct `terraform init` sees the same
# version pin Terragrunt's root generate "versions" block produces (see
# helm-provider.tf) — when actually run through Terragrunt, this file gets
# overwritten by that generated one during the module-source copy, so it
# has zero effect on the real apply path. Keep both in sync.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
  }
}
