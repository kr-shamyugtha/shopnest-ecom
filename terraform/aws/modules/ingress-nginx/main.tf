resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = var.chart_version
  namespace        = "ingress-nginx"
  create_namespace = true

  # Same reasoning as the Azure module, and it matters here for the same
  # reason: the chart's default (externalTrafficPolicy: Cluster) makes the
  # load balancer's health check hit the raw "/" path on the data-plane
  # NodePort, which ingress-nginx's default backend answers with 404 (no
  # Ingress matches an unset Host header). The load balancer then marks the
  # whole target group unhealthy and silently drops ALL external traffic,
  # even though the app works fine internally. "Local" makes Kubernetes
  # provision a dedicated health-check port that always returns 200 for a
  # node with a ready local pod. Also preserves real client source IPs,
  # which Cluster loses.
  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  # ---------------------------------------------------------------
  # NLB wiring — the part with no Azure counterpart
  # ---------------------------------------------------------------
  # On AKS a bare LoadBalancer Service got a public IP from the built-in
  # cloud provider with no annotations at all. On EKS the same Service
  # would produce a legacy Classic Load Balancer; "external" hands it to
  # the AWS Load Balancer Controller instead.
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"
    value = "external"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
    value = "ip"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = var.internet_facing ? "internet-facing" : "internal"
  }

  # Without an explicit health-check path the NLB probes the traffic port
  # with a TCP check, which succeeds against a controller that is up but
  # not yet serving — the same class of false-healthy the Azure side hit
  # from the other direction. /healthz is ingress-nginx's own readiness
  # endpoint on port 10254.
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-healthcheck-protocol"
    value = "HTTP"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-healthcheck-path"
    value = "/healthz"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-healthcheck-port"
    value = "10254"
  }

  # Cross-zone is off by default on an NLB and is not free, but with a
  # single ingress-nginx replica every zone without that pod blackholes
  # traffic otherwise.
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-cross-zone-load-balancing-enabled"
    value = "true"
  }

  set {
    name  = "controller.replicaCount"
    value = var.replica_count
  }
}
