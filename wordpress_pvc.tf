resource "aws_security_group" "sg_efs" {
  description = "Security Group to allow EFS (NFS)"
  name = "efs-sg"
  vpc_id = var.wordpress.vpc_id

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
  subnet_id      = element(var.private_subnet_cidrs[*], count.index)
  security_groups = [ aws_security_group.sg_efs.id ]
}

resource "kubernetes_storage_class" "wordpress" {
  metadata {
    name = "${var.wordpress.name}-efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
}

resource "kubernetes_persistent_volume" "wordpress" {
  metadata {
    name = "${var.wordpress.name}-efs-pv"
  }
  spec {
    capacity = {
      storage = "5Gi"
    }
    volume_mode = "Filesystem"
    access_modes = ["ReadWriteMany"]
    persistent_volume_reclaim_policy = "Retain"
    storage_class_name = "efs-sc"
    persistent_volume_source {
      csi {
        driver = "efs.csi.aws.com"
        volume_handle = aws_efs_file_system.efs.id
      }
    }
  }
  depends_on = [ kubernetes_storage_class.wordpress ]
}