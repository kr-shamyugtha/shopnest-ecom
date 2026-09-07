# A module can only have one required_providers block, ever — this module's
# additional requirement (helm, on top of the root-generated azurerm one) is
# declared in the root terragrunt.hcl's shared generate "versions" block
# instead of here (Terragrunt doesn't allow a child unit to override a
# same-named generate block from a parent, so it's extended at the root
# for every unit rather than per-unit).

provider "kubernetes" {
  host                   = var.cluster_host
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "azurecli", "--server-id", var.aks_aad_server_app_id]
  }
}

provider "helm" {}
