# Present here purely so the IDE / a direct `terraform init` sees the same
# version pins Terragrunt's root generate "versions" block produces — when
# actually run through Terragrunt, this file gets overwritten by that
# generated one, so it has zero effect on the real apply path. Keep both in
# sync (see terraform/azure/live/terragrunt.hcl).
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
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
