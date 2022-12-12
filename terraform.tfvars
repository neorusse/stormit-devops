vpc_config = {
  cidr_block                = "10.0.0.0/16"
  tag                       = "stormit"
}

public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

private_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]

eks_cluster = {
  name                  = "stormit"
  version               = "1.22"
  private_access        = true
  public_access         = true
  public_subnet_ids     = ["subnet-xxx", "subnet-xxx", "subnet-xxx"]
  private_subnet_ids    = ["subnet-xxx", "subnet-xxx", "subnet-xxx"]
  fargate_name          = "stormit-fargate"
}