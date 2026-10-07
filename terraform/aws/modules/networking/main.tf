data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

locals {
  name = "${var.project_name}-${var.environment}"

  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Deterministic /20s carved out of the VPC CIDR so the subnet layout is a
  # pure function of vnet_cidr + az_count — no per-environment subnet lists
  # to keep in sync, which is what the single aks_subnet_cidr input bought
  # on the Azure side.
  #
  # Private (nodes)          : <vpc>.0.0/20,   <vpc>.16.0/20,  <vpc>.32.0/20
  # Public  (load balancers) : <vpc>.128.0/20, <vpc>.144.0/20, <vpc>.160.0/20
  private_subnet_cidrs = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i)]
  public_subnet_cidrs  = [for i in range(var.az_count) : cidrsubnet(var.vpc_cidr, 4, i + 8)]
}

# ==========================================================
# VPC
# ==========================================================

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr

  # Required by the EKS-managed kube-dns/CoreDNS resolution path and by
  # anything using VPC endpoints later.
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${local.name}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${local.name}-igw"
  })
}

# ==========================================================
# Subnets
# ==========================================================
#
# AKS ran on a single subnet because Azure's zone handling is a property of
# the node pool, not the subnet. EKS is different: the control plane needs
# subnets in at least two AZs, and both the node group and the load balancer
# controller pick subnets by tag. So the single aks-subnet becomes a
# private/public pair per AZ.

resource "aws_subnet" "private" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.private_subnet_cidrs[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(var.tags, {
    Name = "${local.name}-private-${local.azs[count.index]}"

    # Consumed by the AWS Load Balancer Controller for internal-facing
    # Services, and by the cluster-autoscaler's subnet discovery.
    "kubernetes.io/role/internal-elb" = "1"
  })
}

resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.public_subnet_cidrs[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${local.name}-public-${local.azs[count.index]}"

    # Without this tag the load balancer controller silently refuses to
    # provision an internet-facing NLB for the ingress-nginx Service — it
    # reports "unable to discover at least one subnet" rather than failing
    # the Service outright, so the symptom looks like a hung Service with a
    # <pending> EXTERNAL-IP, not an obvious tagging error.
    "kubernetes.io/role/elb" = "1"
  })
}

# ==========================================================
# NAT + routing
# ==========================================================

resource "aws_eip" "nat" {
  count = var.single_nat_gateway ? 1 : var.az_count

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${local.name}-nat-eip-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = var.single_nat_gateway ? 1 : var.az_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${local.name}-nat-${count.index}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, {
    Name = "${local.name}-public-rt"
  })
}

resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count = var.single_nat_gateway ? 1 : var.az_count

  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${local.name}-private-rt-${count.index}"
  })
}

resource "aws_route_table_association" "private" {
  count = var.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[var.single_nat_gateway ? 0 : count.index].id
}
