# Everything that used to be a sequence of manual helm/kubectl commands
# after every cluster rebuild: install Argo CD, give it the repo credential,
# install the argocd-apps wrapper (which defines the shopnest and monitoring
# Applications), and the two Secrets the monitoring stack needs before its
# first sync. Atlantis can now apply this like any other unit.
#
# Two of the three secrets it needs are genuinely external credentials
# (an Azure DevOps PAT, a Teams webhook URL) that nothing in Terraform can
# generate — they must be seeded into Key Vault once, by hand, before this
# unit's first apply. See the data sources below for the exact names.
# Everything after that first seed is fully automatic, including across a
# full destroy/recreate of this environment, since the values live in
# Key Vault (which soft-delete recovers) and, for the Grafana password
# below, in Terraform state too (which lives in shopnest-tfstate-rg and is
# never destroyed with the rest of the environment).

data "azurerm_key_vault_secret" "ado_repo_pat" {
  name         = "ado-repo-pat"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "teams_webhook_url" {
  name         = "teams-webhook-url"
  key_vault_id = var.key_vault_id
}

# Generated once; the value then lives in Terraform state (shopnest-tfstate-rg,
# never destroyed) and is written back to Key Vault on every apply, so the
# same password survives a full environment teardown with no manual step —
# unlike the two data sources above, which are genuinely external and can't
# be generated here.
#
# Writing this secret needs Key Vault Secrets Officer on whoever runs this
# module (Contributor alone doesn't cover Key Vault's data plane). Fine for
# now since Atlantis currently runs as a subscription Owner; would need an
# explicit grant if that ever narrows to a dedicated Atlantis identity.
resource "random_password" "grafana_admin" {
  length  = 24
  special = false
}

resource "azurerm_key_vault_secret" "grafana_admin_password" {
  name         = "grafana-admin-password"
  value        = random_password.grafana_admin.result
  key_vault_id = var.key_vault_id
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

# argocd.argoproj.io/secret-type: repository is how Argo CD recognizes this
# as a repo credential rather than an ordinary Secret — see the comment in
# argocd/values.yaml on why the URL needs credentials at all (private repo).
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
