variable "project_name" {
  type = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  type = string
}

variable "resource_group_name" {
  description = "Name of the environment's AWS Resource Group. Not a parent object the way an Azure resource group is — carried through purely so the live/ units keep the same shape as terraform/azure/live."
  type        = string
}

# Deliberately NOT the same numbers as the Azure VNets (10.10/10.20/10.30).
# Keeping the two clouds in disjoint ranges means a VPN or transit peering
# between them during a migration doesn't need renumbering first.
variable "vpc_cidr" {
  type    = string
  default = "10.110.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones to spread subnets across. EKS requires at least 2."
  type        = number
  default     = 3

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 6
    error_message = "EKS requires subnets in at least 2 availability zones, and this module's /20 carve-up supports at most 6."
  }
}

variable "single_nat_gateway" {
  description = "Route every private subnet through one NAT gateway instead of one per AZ. Cheaper, but the NAT's AZ becomes a single point of failure for all egress — appropriate for dev, not for prod."
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
