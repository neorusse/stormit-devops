# NB: xxxxxxx, and *-xxxxxx is a place holder, replace with actual value.

vpc_config = {
  cidr_block  = "10.0.0.0/16"
  tag         = "stormit"
}

public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

eks_cluster = {
  name                  = "stormit"
  version               = "1.22"
  vpc_id                = "vpc-xxxxxxx"
  public_subnet_ids     = ["subnet-xxx", "subnet-xxx", "subnet-xxx"]
  private_subnet_ids    = ["subnet-xxx", "subnet-xxx", "subnet-xxx"]
  fargate_name          = "stormit-fargate"
}

wordpress = {
  name                      = "stormit"
  namespace                 = "stormit"
  replicas                  = 3
  db_engine                 = "aurora-mysql"
  db_engine_version         = "5.7.mysql_aurora.2.03.2"
  azs                       = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  db_cluster_instance_class = "db.r6gd.large"
  db_instance_class         = "db.t2.small"
  db_storage_type           = "io1"
  db_storage                = 50
  iops                      = 1000
  backup_retention_period   = 30
  preferred_backup_window   = "03:00-04:00"
  db_name                   = "stormit-db"
  db_host                   = "xxxxxxxxxx"
  db_user                   = "stormit@admin"
  db_password               = "xxxxxxxxxxxxxxx"
  vpc_id                    = "vpc-xxxxxxx"
  labels                    = {
    app = "stormit"
  }
}

client_vpn = {
  name                = "stormit-vpn"
  server_cert_arn     = "xxxxxxxx"
  client_cert_arn     = "xxxxxxxx"
  client_cidr         = "10.0.1.0/22"
  private_subnet_ids  = ["subnet-xxx", "subnet-xxx", "subnet-xxx"]
}