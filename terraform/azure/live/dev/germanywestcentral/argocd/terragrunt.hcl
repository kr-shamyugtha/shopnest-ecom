include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//argocd"
}

dependency "aks" {
  config_path = "../aks"
  mock_outputs = {
    host                   = "https://mock.example.com:443"
    cluster_ca_certificate = "bW9jaw=="
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

dependency "keyvault" {
  config_path = "../keyvault"
  mock_outputs = {
    vault_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/mock-rg/providers/Microsoft.KeyVault/vaults/mock-kv"
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  cluster_host           = dependency.aks.outputs.host
  cluster_ca_certificate = dependency.aks.outputs.cluster_ca_certificate
  key_vault_id           = dependency.keyvault.outputs.vault_id

  # Read straight from the files Atlantis already plans/applies from, so
  # there's exactly one copy of this config, not one for `helm upgrade` and
  # a second pasted into Terraform.
  install_values = file("${get_repo_root()}/argocd/install-values.yaml")
  apps_values = [
    file("${get_repo_root()}/argocd/values.yaml"),
    file("${get_repo_root()}/argocd/values-monitoring.yaml"),
  ]
}
