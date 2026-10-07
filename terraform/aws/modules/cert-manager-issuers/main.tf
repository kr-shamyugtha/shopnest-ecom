# Split out from the cert-manager module deliberately: kubernetes_manifest
# validates a manifest against the live API server's CRD schema at plan
# time, before anything in the same apply has actually been created. In the
# same module/state as helm_release.cert_manager, that plan runs before the
# chart (and so the ClusterIssuer CRD it installs) exists, and fails with
# "no matches for kind ClusterIssuer" every time — depends_on only orders
# applies, it doesn't defer the plan-time schema check.
#
# As its own Terragrunt unit, applied after cert-manager, the CRD is already
# live in the cluster by the time this one is planned.

# Self-signed — no real domain exists yet, so a trusted Let's Encrypt issuer
# isn't achievable. Swap this for an ACME issuer once a real domain exists.
resource "kubernetes_manifest" "selfsigned_cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "selfsigned-issuer"
    }
    spec = {
      selfSigned = {}
    }
  }
}

# Real, publicly-trusted cert, for any host that needs one. Same issuer as
# the Azure side; HTTP-01 works through ingress-nginx with a nip.io hostname
# on the NLB's IP, so no purchased domain is required.
resource "kubernetes_manifest" "letsencrypt_cluster_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-prod"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = var.acme_registration_email
        privateKeySecretRef = {
          name = "letsencrypt-prod-account-key"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                ingressClassName = "nginx"
              }
            }
          }
        ]
      }
    }
  }
}
