resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.chart_version
  namespace        = "ingress-nginx"
  create_namespace = true

  # The chart's default (externalTrafficPolicy: Cluster) makes Azure's LB
  # health-probe hit the raw "/" path on the data-plane NodePort, which
  # ingress-nginx's default backend answers with 404 (no Ingress matches an
  # unset Host header) — Azure's LB then marks the whole backend unhealthy
  # and silently drops ALL external traffic, even though the app itself
  # works fine internally. "Local" makes Kubernetes provision a dedicated
  # health-check port that always returns 200 for a node with a ready local
  # pod; Azure's cloud-provider automatically points the LB probe at that
  # instead. Also preserves real client source IPs, which Cluster loses.
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }
}
