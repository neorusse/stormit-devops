variable "vpc_config" {}

variable "public_subnet_cidrs" {}

variable "private_subnet_cidrs" {}

################################################################################
# VPC
################################################################################

resource "aws_vpc" "stormit" {
  cidr_block            = var.vpc_config.cidr_block
  enable_dns_support    = true
  enable_dns_hostnames  = true
  tags = { 
    Name = var.vpc_config.tag
  }
}

################################################################################
# Internet Gateway
################################################################################

resource "aws_internet_gateway" "stormit" {
  vpc_id      = aws_vpc.stormit.id
  tags = { 
    Name = "${var.vpc_config.tag}-igw"
  }
}

################################################################################
# Subnets - Public & Private
################################################################################

# Public subnet
resource "aws_subnet" "stormit_public" {
  count                     = length(var.public_subnet_cidrs)
  vpc_id                    = aws_vpc.stormit.id
  cidr_block                = element(var.public_subnet_cidrs, count.index)
  availability_zone         = element(var.azs, count.index)
  map_public_ip_on_launch   = true

  tags = {
    "Name"                          = "StormIT Public Subnet ${count.index + 1}"
    "kubernetes.io/role/elb"        = "1"
    "kubernetes.io/cluster/stormit" = "shared"
  }

  depends_on = [aws_vpc.stormit]
}

# Private subnet
resource "aws_subnet" "stormit_private" {
  count                     = length(var.private_subnet_cidrs)
  vpc_id                    = aws_vpc.stormit.id
  cidr_block                = element(var.private_subnet_cidrs, count.index)
  availability_zone         = element(var.azs, count.index)
  map_public_ip_on_launch   = false

  tags = {
    "Name"                          = "StormIT Privte Subnet ${count.index + 1}"
    "kubernetes.io/role/internal-elb"        = "1"
    "kubernetes.io/cluster/stormit" = "shared"
  }

  depends_on = [aws_vpc.stormit]
}

################################################################################
# NAT Gateway & Elastic IP
################################################################################

resource "aws_eip" "stormit" {
  vpc = true
  tags = { 
    Name = "${var.vpc_config.tag}-eip"
  }
}

resource "aws_nat_gateway" "stormit" {
  count           = length(var.public_subnet_cidrs)
  allocation_id   = aws_eip.stormit.id
  subnet_id       = element(aws_subnet.stormit_public.*.id, count.index)
  tags = { 
    Name = "${var.vpc_config.tag}-nat"
  }

  depends_on      = [aws_internet_gateway.stormit]
}

################################################################################
# Route Table
################################################################################

# Route for Internet Gateway
resource "aws_route_table" "stormit_public" {
  vpc_id = aws_vpc.stormit.id

  route {
      cidr_block  = "0.0.0.0/0"
      gateway_id  = aws_internet_gateway.igw.id
  }

  tags = { 
    Name = "${var.vpc_config.tag}-public-route-table"
  }
}

# Route for NAT
resource "aws_route_table" "stormit_private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.stormit.id

  route {
    cidr_block      = "0.0.0.0/0"
    nat_gateway_id  = element(aws_nat_gateway.stormit.*.id, count.index)

  }

  tags = { 
    Name = "${var.vpc_config.tag}-private-route-table"
  }
}

# Route table associations for both Public & Private Subnets
resource "aws_route_table_association" "stormit_public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.stormit_public[*].id, count.index)
  route_table_id = aws_route_table.stormit_public.id
}

resource "aws_route_table_association" "stormit_private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.stormit_private[*].id, count.index)
  route_table_id = aws_route_table.stormit_private.id
}
