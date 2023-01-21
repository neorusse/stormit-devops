variable "eks_cluster" {}

variable "vpc_id" {}

variable "public_subnet_ids" {}

variable "private_subnet_ids" {}

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
  name                      = var.eks_cluster.name
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  role_arn                  = aws_iam_role.stormit_eks.arn
  version                   = var.eks_cluster.version

  vpc_config {
    subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)
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

# To use IAM roles for service accounts, an IAM OIDC provider must exist for your cluster.
data "tls_certificate" "certificate" {
  url = aws_eks_cluster.stormit_eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.certificate.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.stormit_eks.identity[0].oidc[0].issuer
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
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = var.eks_cluster.name
  }

  selector {
    namespace = "kube-system"
  }

  timeouts {
    create   = "30m"
    delete   = "30m"
  }

  depends_on = [aws_eks_cluster.stormit_eks]
}

########################
## Output
########################

output "cluster_id" {
value  = aws_eks_cluster.stormit_eks.id
}

output "cluster_name" {
  value = aws_eks_cluster.stormit_eks.name
}
