# ==========================================================
# Control plane and node roles
# ==========================================================
#
# AKS uses identity { type = "SystemAssigned" } and Azure creates and wires
# up both the cluster identity and the kubelet identity for you. EKS has no
# equivalent — every role below is the explicit version of something AKS
# does implicitly.

data "aws_iam_policy_document" "cluster_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cluster" {
  name               = "${local.cluster_name}-cluster"
  assume_role_policy = data.aws_iam_policy_document.cluster_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

data "aws_iam_policy_document" "node_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# The kubelet identity equivalent. The Azure side grants this principal
# AcrPull from inside the aks module; here the pull permission comes from
# the managed AmazonEC2ContainerRegistryReadOnly policy below, and the
# registry-side half of the grant lives in the ecr module (ECR scopes access
# with a repository policy, not a role assignment).
resource "aws_iam_role" "node" {
  name               = "${local.cluster_name}-node"
  assume_role_policy = data.aws_iam_policy_document.node_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Shell access to nodes without opening SSH or running a bastion — the
# closest thing to `az aks` node debugging, and the reason no node ever
# needs a public IP or an inbound SSH rule.
resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# ==========================================================
# EBS CSI driver role (IRSA)
# ==========================================================

data "aws_iam_policy_document" "ebs_csi_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${local.cluster_name}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ==========================================================
# Backend workload identity (IRSA)
# ==========================================================
#
# Direct counterpart to the azurerm_user_assigned_identity +
# azurerm_federated_identity_credential pair on the Azure side. The trust
# condition below is the same statement as the Azure federated credential's
# subject: "the service account <workload_service_account> in namespace
# <workload_namespace> on this cluster's issuer, and nothing else".
#
# The permission to actually read secrets is NOT attached here — it is
# granted by the secrets-manager module, mirroring how the Azure Key Vault
# module grants "Key Vault Secrets User" to this identity rather than the
# aks module doing it.

data "aws_iam_policy_document" "backend_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.this.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:sub"
      values   = ["system:serviceaccount:${var.workload_namespace}:${var.workload_service_account}"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_host}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backend" {
  # Name is referenced verbatim by the ci-oidc module's read permission and
  # by the pipeline's `aws iam get-role` lookup — changing the pattern means
  # changing both.
  name               = "${var.project_name}-${var.environment}-backend"
  description        = "ShopNest backend workload identity for ${local.cluster_name}"
  assume_role_policy = data.aws_iam_policy_document.backend_assume.json

  tags = var.tags
}

# ==========================================================
# CI/CD pipeline access (narrower than the cluster admin entry)
# ==========================================================
#
# The Azure side grants "AKS Cluster User" (fetch credentials) plus "AKS
# RBAC Writer" (deploy workloads, but not cluster-admin). EKS access
# entries are the same idea: AmazonEKSEditPolicy is the RBAC Writer
# equivalent, and scoping it to the workload namespace makes it strictly
# narrower than the Azure grant, which applies cluster-wide.

resource "aws_eks_access_entry" "ci" {
  count = var.ci_principal_arn != null ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.ci_principal_arn
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "ci" {
  count = var.ci_principal_arn != null ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.ci_principal_arn
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [var.workload_namespace]
  }

  depends_on = [aws_eks_access_entry.ci]
}

# ==========================================================
# Administrator access
# ==========================================================
#
# Counterpart to admin_group_object_ids. AWS has no group principal for
# this — an EKS access entry takes an IAM role or user ARN, so the input is
# a list of role ARNs (typically one SSO permission-set role per
# environment, which is the closest equivalent to an Entra ID group).

resource "aws_eks_access_entry" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "admin" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = each.value
  policy_arn    = "arn:${data.aws_partition.current.partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.admin]
}
