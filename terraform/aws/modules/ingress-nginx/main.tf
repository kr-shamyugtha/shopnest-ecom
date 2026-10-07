# ---------------------------------------------------------------
# Fixed public IPs
# ---------------------------------------------------------------
# The Azure dev environment reaches Argo CD, Grafana and the app through
# nip.io hostnames on ingress-nginx's static public IP. An NLB's addresses
# are only stable for the lifetime of that NLB, so the same trick on AWS
# would break on every reinstall. Pinning one Elastic IP per public subnet
# gives the NLB addresses that outlive it — the hostnames in the Argo CD and
# monitoring values stay valid across rebuilds, like the Azure static IP.
locals {
  # Units that don't pass their public subnets (staging/prod) keep the
  # controller's own subnet discovery and NLB-assigned addresses.
  pin_ips = var.internet_facing && length(var.public_subnet_ids) > 0
}

resource "aws_eip" "nlb" {
  count  = local.pin_ips ? length(var.public_subnet_ids) : 0
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "ingress-nginx-nlb-${count.index}"
  })
}

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
  # traffic otherwise. (The older cross-zone-load-balancing-enabled
  # annotation is the in-tree provider's; this is the controller's form.)
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-attributes"
    value = "load_balancing.cross_zone.enabled=true"
  }

  # One EIP per subnet, in the same order as the subnets — the controller
  # pairs them positionally. Commas inside a `set` value must be escaped.
  dynamic "set" {
    for_each = local.pin_ips ? [1] : []
    content {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-subnets"
      value = join("\\,", var.public_subnet_ids)
    }
  }

  dynamic "set" {
    for_each = local.pin_ips ? [1] : []
    content {
      name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-eip-allocations"
      value = join("\\,", aws_eip.nlb[*].allocation_id)
    }
  }

  set {
    name  = "controller.replicaCount"
    value = var.replica_count
  }
}
