# ============================================================================
# Argo CD bootstrap
# ============================================================================
# Counterpart to terraform/azure/modules/argocd: install Argo CD, seed the
# Secrets the two Applications need before their first sync, then install
# the argocd-apps wrapper chart that defines the shopnest and monitoring
# Applications. Replaces the manual helm/kubectl sequence after a rebuild.
#
# Two differences from Azure:
#   - The AWS Applications track the public GitHub repo, so no repository
#     credential is needed (Azure Repos is private and needs a PAT).
#   - The Grafana admin password is kept in Secrets Manager rather than Key
#     Vault. Same trade-off as the Azure module: the generated value is in
#     Terraform state, which is encrypted in S3.
# ============================================================================

resource "random_password" "grafana_admin" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "grafana_admin_password" {
  name        = "${var.project_name}/${var.environment}/grafana-admin-password"
  description = "Grafana admin password for the ${var.environment} monitoring stack"

  # Same 7-day soft delete as the app secrets in a non-locked environment.
  recovery_window_in_days = 7

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "grafana_admin_password" {
  secret_id     = aws_secretsmanager_secret.grafana_admin_password.id
  secret_string = random_password.grafana_admin.result
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version
  namespace        = "argocd"
  create_namespace = true

  values = [var.install_values]
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "kubernetes_secret" "grafana_admin_credentials" {
  metadata {
    name      = "grafana-admin-credentials"
    namespace = "monitoring"
  }

  data = {
    admin-user     = "admin"
    admin-password = random_password.grafana_admin.result
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Defines the shopnest and monitoring Applications (argocd/values-aws.yaml
# and argocd/values-monitoring-aws.yaml, passed in like `-f` twice). Depends
# on the Grafana Secret existing first, so the monitoring app's first sync
# cannot race a missing credential.
resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version
  namespace  = "argocd"

  values = var.apps_values

  depends_on = [
    helm_release.argocd,
    kubernetes_secret.grafana_admin_credentials,
  ]
}
