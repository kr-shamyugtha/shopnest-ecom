variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "resource_group_name" {
  description = "Name of the environment's AWS Resource Group. Carried through only so the live/ units keep the same shape as terraform/azure/live."
  type        = string
}

variable "backend_identity_role_name" {
  description = "Name of the backend IRSA role that reads these secrets via the Secrets Store CSI driver. Counterpart to backend_identity_object_id."
  type        = string
}

# Mirrors helm/shopnest/values.yaml secrets.items[].name exactly. Key Vault
# forbids underscores in secret names, which is why these are hyphenated;
# Secrets Manager allows both, and they are kept hyphenated so one items
# list serves both clouds.
variable "secret_names" {
  description = "Secret names to create under <project>/<environment>/."
  type        = list(string)
  default = [
    "CLOUDINARY-API-KEY",
    "CLOUDINARY-API-SECRET",
    "CLOUDINARY-CLOUD-NAME",
    "GMAIL-PASS",
    "GMAIL-USER",
    "JWT-SECRET",
    "MONGO-URI",
    "RAZORPAY-KEY-ID",
    "RAZORPAY-KEY-SECRET",
  ]
}

variable "secrets_officer_principal_arns" {
  description = "Principals allowed to write secret values. Empty relies on account-level IAM only."
  type        = list(string)
  default     = []
}

variable "enable_delete_lock" {
  description = "Lengthen the recovery windows on the secrets and their KMS key. Counterpart to the CanNotDelete lock the Azure module puts on the Key Vault."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
