################################################################################
# Aurora DB Security Group
################################################################################
resource "aws_security_group" "aurora_rds_sg" {
  vpc_id        = var.vpc_id

  ingress {
    description = "Allow only EKS to connect"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [ var.vpc_config.cidr_block ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.wordpress.name}-sg-rds"
  }
}

################################################################################
# Aurora Multi-AZ RDS DB Cluster
################################################################################
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier        = "${var.wordpress.name}-db-subnet"
  engine                    = var.wordpress.db_engine
  engine_version            = var.wordpress.db_engine_version
  availability_zones        = var.wordpress.azs
  db_cluster_instance_class = var.wordpress.db_cluster_instance_class
  allocated_storage         = var.wordpress.db_storage
  storage_type              = var.wordpress.db_storage_type
  iops                      = var.wordpress.iops
  database_name             = var.wordpress.db_name
  master_username           = var.wordpress.db_user
  master_password           = var.wordpress.db_password
  backup_retention_period   = var.wordpress.backup_retention_period
  preferred_backup_window   = var.wordpress.preferred_backup_window
  vpc_security_group_ids    = [aws_security_group.aurora_rds_sg.id]

  tags = {
    Name = "${var.wordpress.name}-rds-sg"
  }
}

resource "aws_rds_cluster_instance" "aurora_cluster_instance" {
  count                  = length(var.private_subnet_cidrs)

  identifier             = "${var.wordpress.name}_aurora_instance_${count.index}"
  cluster_identifier     = aws_rds_cluster.aurora_cluster.id
  instance_class         = var.wordpress.db_instance_class
  engine                 = aws_rds_cluster.aurora_cluster.engine
  engine_version         = aws_rds_cluster.aurora_cluster.engine_version
  db_subnet_group_name   = aws_db_subnet_group.aurora_subnet_group.name

  tags {
    Name         = "${var.wordpress.name}_aurora_instance_${count.index}"
    ManagedBy    = "terraform"
  }
}

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name          = "${var.wordpress.name}_aurora_db_subnet_group"
  description   = "Allowed subnets for Aurora DB cluster instances"
  subnet_ids    = var.private_subnet_cidrs
  tags {
      Name         = "${var.wordpress.name}-Aurora-DB-Subnet-Group"
      ManagedBy    = "terraform"
  }
}

########################
## Output
########################

output "cluster_address" {
    value = "${aws_rds_cluster.aurora_cluster.address}"
}