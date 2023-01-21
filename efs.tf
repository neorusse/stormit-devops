variable "wordpress" {}

resource "aws_security_group" "sg_efs" {
  description = "Security Group to allow EFS (NFS)"
  name = "efs-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = [ var.vpc_config.cidr_block ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "efs" {
  creation_token = "${var.wordpress.name}-efs"

  tags = {
    Name = "${var.wordpress.name}-wordpress-pv"
  }
}

resource "aws_efs_mount_target" "mount_target" {
  count = length(var.private_subnet_cidrs)

  file_system_id = aws_efs_file_system.efs.id
  subnet_id      = element(var.private_subnet_ids[*], count.index)
  security_groups = [ aws_security_group.sg_efs.id ]

  depends_on = [ aws_security_group.sg_efs ]
}