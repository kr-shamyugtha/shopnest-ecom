# ==========================================================
# Subnet-level filtering (the NSG counterpart)
# ==========================================================
#
# The Azure module attaches a Network Security Group to the AKS subnet and
# writes its inbound posture out explicitly rather than leaning on Azure's
# invisible built-in defaults. The AWS object at that layer is a Network
# ACL — but unlike an NSG it is *stateless*, so every allow needs a matching
# return-traffic rule. That difference is the single biggest source of
# "worked on Azure, silently broken on AWS" here, so the rules below are
# written out in full rather than left to the default NACL's allow-all.
#
# The health-probe trap the Azure module documents has a direct analogue:
# NLB health checks originate from the load balancer's ENIs *inside the
# VPC*, not from the internet. An internet-scoped allow list alone marks the
# whole target group unhealthy while the app itself is fine internally —
# same failure signature as Azure's 168.63.129.16 probes being swallowed by
# DenyInternetInbound. Hence the explicit VPC-CIDR allow, first.

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.public[*].id

  tags = merge(var.tags, {
    Name = "${local.name}-public-nacl"
  })
}

# Rule 100 — intra-VPC traffic, including NLB health checks and node ->
# control plane. Must come before the internet rules, same ordering logic
# as the Azure NSG's AllowAzureLBProbes sitting below DenyInternetInbound.
resource "aws_network_acl_rule" "public_in_vpc" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# Rules 150/151 — the ingress controller's public listeners. Direct
# counterpart to AllowIngressInbound.
resource "aws_network_acl_rule" "public_in_http" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 150
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "public_in_https" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 151
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Rule 190 — return traffic for connections opened *from* inside the VPC.
# A stateful NSG needs no equivalent; a NACL does, and omitting it breaks
# every outbound call (image pulls, MongoDB Atlas, Razorpay, Gmail) while
# leaving inbound looking perfectly healthy.
resource "aws_network_acl_rule" "public_in_ephemeral" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 190
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Rule 200 — explicit deny for everything else inbound. Redundant with the
# NACL's implicit final deny, exactly like the Azure module's
# DenyInternetInbound is redundant with DenyAllInBound: it exists so the
# inbound posture is a reviewable line in a `plan` diff rather than an
# assumption.
resource "aws_network_acl_rule" "public_in_deny" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
}

# Outbound stays unrestricted, for the same reason the Azure module keeps
# Azure's default AllowInternetOutBound instead of a service-tag allow-list:
# EKS nodes bootstrap against a set of endpoints (ECR, S3, the EKS API, the
# OS package mirrors) that a CIDR-based list can't cover without gaps, and
# the app itself talks to MongoDB Atlas, Cloudinary, Razorpay and Gmail on
# hosts that move. FQDN-based filtering needs AWS Network Firewall in front
# of it — don't re-add outbound restriction here without it.
resource "aws_network_acl_rule" "public_out_all" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = aws_subnet.private[*].id

  tags = merge(var.tags, {
    Name = "${local.name}-private-nacl"
  })
}

resource "aws_network_acl_rule" "private_in_vpc" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
}

# Return traffic for the nodes' own outbound connections, arriving back
# through the NAT gateway.
resource "aws_network_acl_rule" "private_in_ephemeral" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 190
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  to_port        = 65535
}

# Nodes are never addressed directly from the internet — all external
# traffic arrives via the NLB in the public subnets, which is covered by
# the intra-VPC rule above.
resource "aws_network_acl_rule" "private_in_deny" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_out_all" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

# ==========================================================
# Security groups
# ==========================================================
#
# Stateful, so these are the closer behavioural match to an Azure NSG. The
# NACLs above are the coarse subnet-level backstop; these are where the
# real per-workload scoping lives.

resource "aws_security_group" "cluster" {
  name        = "${local.name}-eks-cluster-sg"
  description = "EKS control plane <-> node communication for ${local.name}"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name}-eks-cluster-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "node" {
  name        = "${local.name}-eks-node-sg"
  description = "EKS worker nodes for ${local.name}"
  vpc_id      = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name}-eks-node-sg"

    # The in-cluster AWS cloud controller looks for this tag when it needs
    # to attach load balancer rules to the node security group.
    "kubernetes.io/cluster/${local.name}-eks" = "owned"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "node_from_node" {
  security_group_id            = aws_security_group.node.id
  description                  = "Pod-to-pod traffic between nodes"
  referenced_security_group_id = aws_security_group.node.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "node_from_cluster" {
  security_group_id            = aws_security_group.node.id
  description                  = "Control plane to kubelet / webhooks"
  referenced_security_group_id = aws_security_group.cluster.id
  from_port                    = 1025
  to_port                      = 65535
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "node_from_cluster_webhook" {
  security_group_id            = aws_security_group.node.id
  description                  = "Control plane to admission/conversion webhooks on 443 (cert-manager, load balancer controller)"
  referenced_security_group_id = aws_security_group.cluster.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

# The NLB provisioned for the ingress-nginx Service runs in "ip" target
# mode, so its health checks and data-plane traffic arrive from inside the
# VPC and land on the pod IP directly. Scoping this to the VPC CIDR rather
# than 0.0.0.0/0 keeps nodes unreachable from the internet even if a subnet
# is ever mis-tagged as public.
resource "aws_vpc_security_group_ingress_rule" "node_from_lb" {
  security_group_id = aws_security_group.node.id
  description       = "NLB data plane and health checks"
  cidr_ipv4         = var.vpc_cidr
  from_port         = 1025
  to_port           = 65535
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "node_all" {
  security_group_id = aws_security_group.node.id
  description       = "Unrestricted egress - see the NACL comment above for why"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "cluster_from_node" {
  security_group_id            = aws_security_group.cluster.id
  description                  = "Nodes to the Kubernetes API"
  referenced_security_group_id = aws_security_group.node.id
  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "cluster_all" {
  security_group_id = aws_security_group.cluster.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
