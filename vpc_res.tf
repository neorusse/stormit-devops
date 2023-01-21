variable "vpc_config" {}

variable "public_subnet_cidrs" {}

variable "private_subnet_cidrs" {}

variable "azs" {}

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
  count                     = 3
  vpc_id                    = aws_vpc.stormit.id
  cidr_block                = element(var.public_subnet_cidrs, count.index)
  availability_zone         = element(var.azs, count.index)
  map_public_ip_on_launch   = true

  tags = {
    "Name"                          = "StormIT Public Subnet ${count.index + 1}"
    "kubernetes.io/role/elb"        = 1
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
    "Name"                            = "StormIT Privte Subnet ${count.index + 1}"
    "kubernetes.io/role/internal-elb" = 1
    "kubernetes.io/cluster/stormit"   = "shared"
  }

  depends_on = [aws_vpc.stormit]
}

################################################################################
# NAT Gateway & Elastic IP
################################################################################

resource "aws_eip" "stormit" {
  count   = length(var.public_subnet_cidrs)
  vpc     = true
  tags    = { 
    Name = "${var.vpc_config.tag}-eip"
  }
}

resource "aws_nat_gateway" "stormit" {
  count           = length(var.public_subnet_cidrs)
  allocation_id   = element(aws_eip.stormit.*.id, count.index)
  subnet_id       = element(aws_subnet.stormit_public.*.id, count.index)
  tags = { 
    Name = "${var.vpc_config.tag}-nat-${count.index + 1}"
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
      gateway_id  = aws_internet_gateway.stormit.id
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

  depends_on = [aws_route_table.stormit_public, aws_subnet.stormit_public]
}

resource "aws_route_table_association" "stormit_private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.stormit_private[*].id, count.index)
  route_table_id = element(aws_route_table.stormit_private[*].id, count.index)

  depends_on = [aws_route_table.stormit_private, aws_subnet.stormit_private]
}

########################
## Output
########################

output "aws_subnets_public" {
  value   = aws_subnet.stormit_public.*.id
}

output "aws_subnets_private" {
  value   = aws_subnet.stormit_private.*.id
}

output "vpc_id" {
  value  = aws_vpc.stormit.id
}