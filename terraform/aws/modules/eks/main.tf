locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"

  # IRSA trust-policy conditions key off the issuer *without* its scheme —
  # "oidc.eks.<region>.amazonaws.com/id/ABC123", not the full https:// URL.
  # Leaving the scheme on makes the condition silently never match, which
  # surfaces much later as an opaque AccessDenied from the pod.
  oidc_issuer_host = replace(aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

# ==========================================================
# Control plane
# ==========================================================

# Envelope encryption for Kubernetes Secrets at rest. AKS gets the
# equivalent implicitly (etcd is encrypted with a Microsoft-managed key);
# on EKS it is opt-in and needs a key of its own.
resource "aws_kms_key" "secrets" {
  description             = "Envelope encryption for ${local.cluster_name} Kubernetes secrets"
  enable_key_rotation     = true
  deletion_window_in_days = var.enable_delete_lock ? 30 : 7

  tags = var.tags
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.cluster_name}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    security_group_ids      = [var.cluster_security_group_id]
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs
  }

  kubernetes_network_config {
    service_ipv4_cidr = var.service_ipv4_cidr
    ip_family         = "ipv4"
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.secrets.arn
    }
    resources = ["secrets"]
  }

  # The direct counterpart to AKS's local_account_disabled = true plus
  # azure_rbac_enabled: "API" means the aws-auth ConfigMap is ignored
  # entirely and the only way in is an EKS access entry backed by IAM.
  # There is no static kubeconfig admin credential to leak.
  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = false
  }

  # Nearest analogue to AKS's sku_tier. STANDARD support ends at a version's
  # normal EOL; EXTENDED buys ~12 more months of patches at extra cost —
  # the same "pay for a stronger control-plane guarantee" decision.
  upgrade_policy {
    support_type = var.support_type
  }

  # AKS ships control-plane diagnostics through Azure Monitor. On EKS these
  # are off by default and silently unavailable after the fact, so the audit
  # and authenticator logs in particular are enabled up front.
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # EKS only honours bootstrap_cluster_creator_admin_permissions at create
  # time and keeps reporting the old value afterwards, which would otherwise
  # show up as a permanent diff on every plan.
  lifecycle {
    ignore_changes = [access_config[0].bootstrap_cluster_creator_admin_permissions]
  }

  tags = merge(var.tags, {
    Name = local.cluster_name
  })

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_cloudwatch_log_group.cluster,
  ]
}

resource "aws_cloudwatch_log_group" "cluster" {
  name              = "/aws/eks/${local.cluster_name}/cluster"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# ==========================================================
# OIDC provider (the oidc_issuer_enabled / workload_identity_enabled pair)
# ==========================================================
#
# AKS turns both of these on with a boolean and manages the issuer for you.
# On EKS the issuer exists as soon as the cluster does, but nothing trusts
# it until it is registered with IAM as an OIDC provider — that registration
# is what makes IRSA (the workload-identity equivalent) work at all.

data "tls_certificate" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc.certificates[0].sha1_fingerprint]

  tags = var.tags
}

# ==========================================================
# Node group (the default_node_pool counterpart)
# ==========================================================

resource "aws_eks_node_group" "system" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "system"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.private_subnet_ids

  instance_types = [var.instance_type]
  capacity_type  = var.capacity_type
  disk_size      = var.node_disk_size

  scaling_config {
    # EKS has no equivalent of AKS's "auto_scaling toggles between
    # node_count and min/max" — desired_size is always required. When
    # autoscaling is on, cluster-autoscaler owns desired_size from then on
    # (see the ignore_changes below), so it only seeds the initial size.
    desired_size = var.enable_auto_scaling ? var.min_count : var.node_count
    min_size     = var.enable_auto_scaling ? var.min_count : var.node_count
    max_size     = var.enable_auto_scaling ? var.max_count : var.node_count
  }

  # AKS expresses node upgrades as max_surge ("1" adds a temporary extra
  # node, which needs spare quota). EKS managed node groups express the same
  # thing the other way round, as max_unavailable — nodes are replaced in
  # place, so an upgrade needs no additional vCPU headroom at all. That
  # removes the quota trap documented on the staging/prod Azure units, where
  # a version upgrade would have required a temporary third node the
  # regional quota could not accommodate.
  update_config {
    max_unavailable = var.node_max_unavailable
  }

  labels = {
    "node.kubernetes.io/role" = "system"
  }

  tags = merge(var.tags, {
    Name = "${local.cluster_name}-system"

    # cluster-autoscaler discovers which node groups it may scale by these
    # two tags. Without them it runs, logs nothing obviously wrong, and
    # simply never scales anything.
    "k8s.io/cluster-autoscaler/enabled"               = var.enable_auto_scaling ? "true" : "false"
    "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
  })

  lifecycle {
    # cluster-autoscaler changes desired_size at runtime. Without this,
    # every subsequent plan would try to drag the cluster back to the seed
    # value and undo real scaling decisions.
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_worker,
    aws_iam_role_policy_attachment.node_cni,
    aws_iam_role_policy_attachment.node_ecr,
  ]
}

# ==========================================================
# Add-ons
# ==========================================================
#
# AKS bundles CNI, CoreDNS, kube-proxy, a CSI driver set and metrics-server
# into the cluster resource itself. On EKS the first three are explicit
# managed add-ons, EBS CSI needs its own IRSA role, and metrics-server is
# not provided at all (it gets its own Helm module — the HPAs in the chart
# do not work without it).

# Azure CNI Overlay gives pods addresses from a separate pod_cidr that never
# touches the VNet. The AWS VPC CNI has no such mode by default — pods take
# real subnet IPs, which is why the private subnets here are /20s rather than
# the single /24 the AKS subnet could get away with.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "vpc-cni"
  addon_version = var.addon_versions.vpc_cni

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "kube-proxy"
  addon_version = var.addon_versions.kube_proxy

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "coredns"
  addon_version = var.addon_versions.coredns

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  # CoreDNS pods are scheduled onto nodes, so the node group has to exist
  # first or the add-on installs into a cluster with nowhere to run and
  # reports DEGRADED.
  depends_on = [aws_eks_node_group.system]

  tags = var.tags
}

# The monitoring stack's PVCs (Prometheus 10Gi, Grafana 5Gi, Loki 10Gi,
# Alertmanager 2Gi) have no provisioner on a bare EKS cluster — AKS ships
# one by default, EKS does not.
resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  addon_version            = var.addon_versions.ebs_csi
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.system]

  tags = var.tags
}
