resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = var.chart_version
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }
}

# Self-signed — no real domain exists yet, so a trusted Let's Encrypt issuer
# isn't achievable. Same position as the Azure module. Swap this for an ACME
# issuer once a real domain exists; on AWS the natural upgrade is DNS-01
# against Route 53, which needs an IRSA role for cert-manager with
# route53:ChangeResourceRecordSets on the hosted zone.
resource "kubernetes_manifest" "selfsigned_cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "selfsigned-issuer"
    }
    spec = {
      selfSigned = {}
    }
  }

  depends_on = [helm_release.cert_manager]
}
