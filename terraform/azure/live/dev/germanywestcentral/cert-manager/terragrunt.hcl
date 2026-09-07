include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//cert-manager"
}

dependency "aks" {
  config_path = "../aks"
  mock_outputs = {
    host                   = "https://mock.example.com:443"
    cluster_ca_certificate = "bW9jaw=="
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

inputs = {
  cluster_host           = dependency.aks.outputs.host
  cluster_ca_certificate = dependency.aks.outputs.cluster_ca_certificate
}
