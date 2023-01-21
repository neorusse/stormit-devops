################################################################################
# Application Load Balancer
################################################################################

#iam policy for the controller
data "http" "iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.2.0/docs/install/iam_policy.json"
  request_headers = {
    Accept = "application/json"
  }
}

resource "aws_iam_policy" "ALB-policy" {
  name   = "ALBIngressControllerIAMPolicy"
  policy = data.http.iam_policy.response_body
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "elb_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.cluster.identity[0].oidc[0].issuer, "https://", "")}"]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_alb_ingress_controller" {
  name        = "eks-alb-ingress-controller"
  description = "Permissions required by the Kubernetes AWS ALB Ingress controller to do its job."
  force_detach_policies = true
  assume_role_policy = data.aws_iam_policy_document.elb_assume_role_policy.json

}

resource "aws_iam_role_policy_attachment" "ALB-policy_attachment" {
  policy_arn = aws_iam_policy.ALB-policy.arn
  role       = aws_iam_role.eks_alb_ingress_controller.name
}