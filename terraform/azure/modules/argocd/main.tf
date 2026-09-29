
data "azurerm_key_vault_secret" "ado_repo_pat" {
  name         = "ado-repo-pat"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "teams_webhook_url" {
  name         = "teams-webhook-url"
  key_vault_id = var.key_vault_id
}

resource "random_password" "grafana_admin" {
  length  = 24
  special = false
}

resource "azurerm_key_vault_secret" "grafana_admin_password" {
  # checkov:skip=CKV_AZURE_41: No expiry on purpose. Key Vault refuses to serve an expired secret, and
  # nothing rotates this password yet, so a fixed date would break Grafana login when it passed.
  # Revisit when rotation exists (e.g. time_rotating feeding random_password keepers).
  name         = "grafana-admin-password"
  value        = random_password.grafana_admin.result
  key_vault_id = var.key_vault_id
  content_type = "password"
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

resource "kubernetes_secret" "ado_repo" {
  metadata {
    name      = "shopnest-ado-repo"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type     = "git"
    url      = var.repo_url
    username = "pat"
    password = data.azurerm_key_vault_secret.ado_repo_pat.value
  }

  depends_on = [helm_release.argocd]
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

resource "kubernetes_secret" "shopnest_teams_webhook" {
  metadata {
    name      = "shopnest-teams-webhook"
    namespace = "monitoring"
  }

  data = {
    webhook-url = data.azurerm_key_vault_secret.teams_webhook_url.value
  }

  depends_on = [kubernetes_namespace.monitoring]
}

# Defines the shopnest and monitoring Applications (argocd/values.yaml and
# argocd/values-monitoring.yaml, passed in like `-f` twice). Depends on every
# Secret above existing first, so neither app's first sync can race a
# missing credential.
resource "helm_release" "argocd_apps" {
  name       = "argocd-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = var.argocd_apps_chart_version
  namespace  = "argocd"

  values = var.apps_values

  depends_on = [
    kubernetes_secret.ado_repo,
    kubernetes_secret.grafana_admin_credentials,
    kubernetes_secret.shopnest_teams_webhook,
  ]
}
