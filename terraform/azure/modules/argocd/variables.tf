variable "cluster_host" {
  description = "AKS API server endpoint"
  type        = string
  sensitive   = true
}

variable "cluster_ca_certificate" {
  description = "AKS cluster CA certificate (base64)"
  type        = string
  sensitive   = true
}

variable "aks_aad_server_app_id" {
  description = "Well-known Azure Kubernetes Service AAD Server application ID (public cloud), used by kubelogin for token exec auth"
  type        = string
  default     = "6dae42f8-4368-4678-94ff-3960e28e3630"
}

variable "key_vault_id" {
  description = "Resource ID of the Key Vault holding ado-repo-pat and teams-webhook-url (seeded by hand once) and grafana-admin-password (written by this module)."
  type        = string
}

variable "repo_url" {
  description = "HTTPS clone URL of the private Azure Repos repo, for the repo credential Secret. Matches argocd/values.yaml's repoURL."
  type        = string
  default     = "https://dev.azure.com/kavitography/shopnest-ado/_git/shopnest-ado"
}

variable "install_values" {
  description = "Contents of argocd/install-values.yaml, passed through as-is."
  type        = string
}

variable "apps_values" {
  description = "Contents of argocd/values.yaml and argocd/values-monitoring.yaml, in that order — passed to argocd-apps the same way `-f` twice would be."
  type        = list(string)
}

variable "argocd_chart_version" {
  type    = string
  default = "10.9.2"
}

variable "argocd_apps_chart_version" {
  type    = string
  default = "2.0.5"
}
