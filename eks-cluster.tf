variable "eks_cluster" {}

data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.stormit_eks.id
}

data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.stormit_eks.id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.10"
}

 ################################################################################
# EKS Cluster
################################################################################

resource "aws_iam_role" "stormit_eks" {
  name = var.eks_cluster.name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.stormit_eks.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.stormit_eks.name
}

resource "aws_eks_cluster" "stormit_eks" {
  name     = var.eks_cluster.name
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  role_arn = aws_iam_role.stormit_eks.arn

  vpc_config {
    subnet_ids = concat(var.eks_cluster.public_subnet_ids, var.eks_cluster.private_subnet_ids)
  }

  tags = {
    Name = var.eks_cluster.name
  }
  depends_on = [
    aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.AmazonEKSServicePolicy
  ]

  timeouts {
    delete    = "30m"
  }
}

################################################################################
# Fargate Profile
################################################################################

resource "aws_iam_role" "fargate_pod_execution_role" {
  name                  = "eks-fargate-pod-execution-role"
  force_detach_policies = true

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "eks.amazonaws.com",
          "eks-fargate-pods.amazonaws.com"
          ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.fargate_pod_execution_role.name
}

resource "aws_eks_fargate_profile" "stormit_eks" {
  cluster_name           = var.eks_cluster.name
  fargate_profile_name   = var.eks_cluster.fargate_name
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution_role.arn
  subnet_ids             = var.eks_cluster.private_subnet_ids

  selector {
    namespace = var.eks_cluster.name
  }

  timeouts {
    create   = "30m"
    delete   = "30m"
  }
}
