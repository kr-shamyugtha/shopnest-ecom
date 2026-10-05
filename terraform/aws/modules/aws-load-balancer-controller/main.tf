# ============================================================================
# AWS Load Balancer Controller
# ============================================================================
# No Azure counterpart: on AKS, a Service of type LoadBalancer is satisfied
# by the built-in cloud provider, which is how ingress-nginx got its public
# IP with nothing else installed. On EKS the in-tree path only produces a
# legacy Classic Load Balancer, so this controller is what turns the
# ingress-nginx Service into a real NLB — and, critically, into an
# "ip"-target NLB that sends traffic straight to pod IPs.
#
# That target mode is what makes the ingress-nginx module's
# externalTrafficPolicy: Local setting behave the same way it does on
# Azure: health checks and data-plane traffic reach the pod directly rather
# than bouncing through a NodePort that answers 404 for an unset Host
# header.
# ============================================================================

data "aws_iam_policy_document" "assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.cluster_name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

# The controller's permission set is large and AWS revises it with each
# release, so it is kept as a maintained JSON document alongside this module
# rather than hand-written here. Refresh it from the upstream release that
# matches chart_version when bumping.
resource "aws_iam_policy" "this" {
  name        = "${var.cluster_name}-alb-controller"
  description = "AWS Load Balancer Controller permissions for ${var.cluster_name}"
  policy      = file("${path.module}/iam-policy.json")

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "helm_release" "this" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = var.chart_version
  namespace        = "kube-system"
  create_namespace = false

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.this.arn
  }

  # Two replicas is the chart default and it does not fit on a two-node
  # cluster already running the app, Argo CD and the monitoring stack —
  # the same capacity constraint documented throughout the Azure side.
  set {
    name  = "replicaCount"
    value = var.replica_count
  }

  depends_on = [aws_iam_role_policy_attachment.this]
}
