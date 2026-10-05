# ============================================================================
# Cluster Autoscaler
# ============================================================================
# On AKS, auto_scaling_enabled on the node pool is the whole feature — the
# managed control plane runs the autoscaler for you. An EKS managed node
# group's min/max are only bounds; nothing moves desired_size between them
# unless this is running. Without it, enable_auto_scaling on the eks module
# would be a setting that quietly does nothing.
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
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.cluster_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "this" {
  # Discovery is account-wide: the autoscaler has to enumerate ASGs to find
  # the ones tagged for this cluster, and it cannot filter server-side.
  statement {
    sid    = "Discover"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeImages",
      "eks:DescribeNodegroup",
    ]

    resources = ["*"]
  }

  # Mutation is not: scoped by the autoscaler-discovery tag the eks module
  # puts on the node group, so this role can only resize groups belonging
  # to its own cluster.
  statement {
    sid    = "ScaleOwnNodeGroups"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/${var.cluster_name}"
      values   = ["owned"]
    }
  }
}

resource "aws_iam_policy" "this" {
  name        = "${var.cluster_name}-cluster-autoscaler"
  description = "Cluster Autoscaler permissions for ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.this.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "helm_release" "this" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.chart_version
  namespace  = "kube-system"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.this.arn
  }

  # The autoscaler refuses to evict pods backed by a PodDisruptionBudget it
  # cannot satisfy, and both app Deployments have one (minAvailable: 1). On
  # a cluster this small that is the desired behaviour — a scale-down should
  # lose to availability — so this stays at the chart default rather than
  # being forced.
  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }

  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }

  depends_on = [aws_iam_role_policy_attachment.this]
}
