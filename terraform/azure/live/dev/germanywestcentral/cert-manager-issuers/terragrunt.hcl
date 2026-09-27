include "root" {
  path = find_in_parent_folders()
}

terraform {
  source = "${get_repo_root()}/terraform/azure/modules//cert-manager-issuers"
}

dependency "aks" {
  config_path = "../aks"
  mock_outputs = {
    host                   = "https://mock.example.com:443"
    cluster_ca_certificate = "bW9jaw=="
  }
  mock_outputs_allowed_terraform_commands = ["validate"]
}

# Ordering only, no outputs used — the ClusterIssuer CRD this unit's
# resources need has to already be live, which only cert-manager's own
# apply (not just its plan) guarantees. See cert-manager-issuers/main.tf.
dependencies {
  paths = ["../cert-manager"]
}

inputs = {
  cluster_host            = dependency.aks.outputs.host
  cluster_ca_certificate  = dependency.aks.outputs.cluster_ca_certificate
  acme_registration_email = "kavitography@gmail.com"
}
