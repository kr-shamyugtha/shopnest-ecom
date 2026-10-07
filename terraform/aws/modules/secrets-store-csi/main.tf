# ============================================================================
# Secrets Store CSI driver + AWS provider
# ============================================================================
# On AKS this is not a module at all — it is the key_vault_secrets_provider
# block inside the cluster resource, with secret_rotation_enabled = true.
# EKS has no such add-on, so the driver and its cloud provider have to be
# installed explicitly, or the chart's SecretProviderClass has nothing to
# act on and the backend pod hangs at ContainerCreating with a
# FailedMount event rather than failing outright.
# ============================================================================

resource "helm_release" "csi_driver" {
  name             = "secrets-store-csi-driver"
  repository       = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart            = "secrets-store-csi-driver"
  version          = var.driver_chart_version
  namespace        = "kube-system"
  create_namespace = false

  # The counterpart to secret_rotation_enabled on the AKS add-on. Off by
  # default in this chart, which means a rotated secret in Secrets Manager
  # would never reach a running pod.
  set {
    name  = "enableSecretRotation"
    value = "true"
  }

  set {
    name  = "rotationPollInterval"
    value = var.rotation_poll_interval
  }

  # The chart's SecretProviderClass -> Kubernetes Secret sync is opt-in.
  # The backend Deployment consumes its secrets through envFrom/secretRef,
  # not by reading the mounted files, so without this the pod starts with
  # every secret env var missing.
  set {
    name  = "syncSecret.enabled"
    value = "true"
  }

  # The AWS provider authenticates as the mounting pod using a service
  # account token the driver requests on its behalf. Pod Identity (used
  # instead of IRSA, see the eks module) only accepts tokens minted for the
  # pods.eks.amazonaws.com audience; without this the provider gets no
  # credentials and the backend mount fails.
  set {
    name  = "tokenRequests[0].audience"
    value = "pods.eks.amazonaws.com"
  }
}

resource "helm_release" "aws_provider" {
  name       = "secrets-store-csi-driver-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  version    = var.aws_provider_chart_version
  namespace  = "kube-system"

  # The provider daemonset registers itself with the driver's socket
  # directory; installing it first leaves it with nothing to register
  # against and it crash-loops until the driver appears.
  depends_on = [helm_release.csi_driver]
}
