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

# The two ClusterIssuers that depend on this chart's CRDs live in the
# cert-manager-issuers module/unit instead, applied as a separate Terragrunt
# unit right after this one. kubernetes_manifest validates a manifest
# against the live API server's CRD schema at plan time — in the same
# apply as the chart that installs that CRD, the plan runs before the CRD
# exists and fails every time, and depends_on can't fix it since it only
# orders applies, not the plan-time check. See that module for the rest.