# ============================================================================
# metrics-server
# ============================================================================
# AKS installs this as part of the managed control plane, so the Azure stack
# never had to think about it. EKS does not ship it at all — and without it
# every HorizontalPodAutoscaler in helm/shopnest (backend and frontend both)
# sits at "unknown" for its CPU target and never scales, while looking
# perfectly healthy in `kubectl get hpa` output apart from that one column.
# ============================================================================

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server"
  chart            = "metrics-server"
  version          = var.chart_version
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "args[0]"
    value = "--kubelet-preferred-address-types=InternalIP\\,Hostname\\,ExternalIP"
  }

  set {
    name  = "resources.requests.cpu"
    value = "25m"
  }

  set {
    name  = "resources.requests.memory"
    value = "64Mi"
  }
}
