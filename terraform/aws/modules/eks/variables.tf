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

variable "private_subnet_ids" {
  description = "Subnets the control-plane ENIs and the node group live in. EKS requires at least two AZs. Counterpart to the Azure module's single subnet_id."
  type        = list(string)
}

variable "cluster_security_group_id" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = null
}

variable "node_count" {
  type    = number
  default = 1
}

variable "enable_auto_scaling" {
  type    = bool
  default = false
}

variable "min_count" {
  type    = number
  default = null
}

variable "max_count" {
  type    = number
  default = null
}

# AKS Standard_D2s_v7 is 2 vCPU / 8 GiB. t3.large is the closest general
# -purpose AWS shape at 2 vCPU / 8 GiB; m6i.large is the non-burstable
# equivalent if sustained CPU matters.
variable "instance_type" {
  type    = string
  default = "t3.large"
}

variable "capacity_type" {
  description = "ON_DEMAND or SPOT. Spot has no Azure equivalent in use here; leave ON_DEMAND to match the AKS node pools."
  type        = string
  default     = "ON_DEMAND"

  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "capacity_type must be ON_DEMAND or SPOT."
  }
}

variable "node_disk_size" {
  type    = number
  default = 50
}

variable "node_max_unavailable" {
  description = "Nodes replaced at a time during an upgrade. EKS replaces in place, so unlike the AKS max_surge this needs no spare vCPU quota."
  type        = number
  default     = 1
}

# The AWS VPC CNI has no overlay mode, so there is no pod_cidr input — pods
# take real addresses from the private subnets. This is the Services range
# instead, which must not overlap the VPC CIDR.
variable "service_ipv4_cidr" {
  description = "CIDR the Kubernetes Service ClusterIPs are allocated from. Must not overlap the VPC CIDR."
  type        = string
  default     = "172.20.0.0/16"
}

variable "workload_namespace" {
  type    = string
  default = "shopnest"
}

variable "workload_service_account" {
  type    = string
  default = "shopnest-backend"
}

variable "support_type" {
  description = "EKS control plane support window (STANDARD or EXTENDED). Nearest analogue to the AKS sku_tier choice — EXTENDED costs more and buys a longer patched life for a Kubernetes version."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "EXTENDED"], var.support_type)
    error_message = "support_type must be STANDARD or EXTENDED."
  }
}

variable "endpoint_public_access" {
  description = "Expose the Kubernetes API endpoint publicly. Needed for CI and for running terragrunt from a laptop; the API is still IAM-authenticated."
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "Source ranges allowed to reach the public API endpoint. Narrow this to the CI egress ranges and the office/VPN ranges once they are known."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "Control-plane logs shipped to CloudWatch. AKS routes these through Azure Monitor by default; on EKS they are off unless named here, and cannot be recovered retroactively."
  type        = list(string)
  default     = ["api", "audit", "authenticator"]
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "addon_versions" {
  description = "Managed add-on versions. Null lets EKS pick the default for the cluster's Kubernetes version, which is usually what you want."
  type = object({
    vpc_cni    = optional(string)
    kube_proxy = optional(string)
    coredns    = optional(string)
    ebs_csi    = optional(string)

    pod_identity_agent = optional(string)
  })
  default = {}
}

variable "enable_delete_lock" {
  description = "Signals a protected environment. Currently lengthens the KMS key's deletion window; AWS has no cluster-wide lock equivalent to Azure's CanNotDelete."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "ci_principal_arn" {
  description = "ARN of the CI/CD pipeline's IAM role, granted namespace-scoped edit access (not cluster-admin). Null skips the grant. Counterpart to the Azure module's ci_principal_id."
  type        = string
  default     = null
}

variable "admin_principal_arns" {
  description = "IAM role ARNs with cluster-admin access. Counterpart to admin_group_object_ids — typically one IAM Identity Center permission-set role per environment."
  type        = list(string)

  validation {
    condition     = length(var.admin_principal_arns) > 0
    error_message = "At least one administrator principal must be configured."
  }
}

variable "enable_network_policy" {
  description = "Turn on the VPC CNI's NetworkPolicy enforcement, so the chart's policies behave as they do on AKS."
  type        = bool
  default     = true
}
