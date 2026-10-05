# Same pattern as cert-manager/ingress-nginx — see the comment there. This
# module additionally uses the kubernetes provider directly (not just via
# helm_release) for the namespace and the three bootstrap Secrets.

provider "helm" {
  kubernetes {
    host                   = var.cluster_host
    cluster_ca_certificate = base64decode(var.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "kubelogin"
      args        = ["get-token", "--login", "azurecli", "--server-id", var.aks_aad_server_app_id]
    }
  }
}

provider "kubernetes" {
  host                   = var.cluster_host
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args        = ["get-token", "--login", "azurecli", "--server-id", var.aks_aad_server_app_id]
  }
}
