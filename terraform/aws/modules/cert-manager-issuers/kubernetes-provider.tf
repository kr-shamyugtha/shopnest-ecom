# kubernetes on top of the root-generated aws provider; declared in the
# root terragrunt.hcl's shared generate "versions" block, same as every
# other add-on module (see cert-manager/helm-provider.tf).

provider "kubernetes" {
  host                   = var.cluster_host
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
  }
}
