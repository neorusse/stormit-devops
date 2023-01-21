
################################################################################
# Application Load Balancer Ingress Controller
################################################################################

resource "helm_release" "ingress-lb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.5"
  namespace  = "kube-system"
  atomic     = true

  set {
    name  = "clusterName"
    value = var.eks_cluster.name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.ingress.metadata[0].name
  }
  set {
    name  = "region"
    value = "eu-central-1"
  }
  set {
    name  = "vpcId"
    value = var.vpc_id
  }
  depends_on = [kubernetes_cluster_role_binding.ingress]
}