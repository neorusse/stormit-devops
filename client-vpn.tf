# Follow the guide in the AWS Client VPN section of the README to generate the root CA,
# Client and Server certificate and key. And to upload them to AWS Certificate Manager ACM.

variable "client_vpn" {}

################################################################################
# VPN Connection SG
################################################################################

resource "aws_security_group" "vpn_access" {
  name = "${var.client_vpn.name}-sg"
  vpc_id = var.vpc_id
  
  ingress {
    from_port = 443
    protocol = "-1"
    to_port = 443
    cidr_blocks = ["0.0.0.0/0"]
    description = "Incoming VPN connection"
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.client_vpn.name
  }
}

################################################################################
# Create VPN
################################################################################
resource "aws_ec2_client_vpn_endpoint" "vpn" {
  description = "StormIT Client VPN endpoint"
  client_cidr_block = var.client_vpn.client_cidr
  split_tunnel = true
  server_certificate_arn = var.client_vpn.server_cert_arn

  authentication_options {
    type = "certificate-authentication"
    root_certificate_chain_arn = var.client_vpn.server_cert_arn
  }

  connection_log_options {
    enabled = true
  }

  tags = {
    Name = var.client_vpn.name
  }
}

resource "aws_ec2_client_vpn_network_association" "vpn_subnets" {
  count                  = length(var.private_subnet_cidrs)

  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  subnet_id              = element(aws_subnet.stormit_private[*].id, count.index)
  security_groups        = [aws_security_group.vpn_access.id]

  lifecycle {
    // The issue why we are ignoring changes is that on every change
    // terraform screws up most of the vpn assosciations
    // see: https://github.com/hashicorp/terraform-provider-aws/issues/14717
    ignore_changes = [subnet_id]
  }
}

resource "aws_ec2_client_vpn_authorization_rule" "vpn_auth_rule" {
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.vpn.id
  target_network_cidr = aws_subnet.stormit_private.cidr_block
  authorize_all_groups = true
}