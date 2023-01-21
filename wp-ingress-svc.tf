resource "kubernetes_service" "wordpress" {
  metadata {
    name = "${var.wordpress.name}-service"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels = var.wordpress.labels
  }
  spec {
    selector = var.wordpress.labels
    type  = "NodePort"
    port {
      port = 80
      target_port = 80
      protocol = "TCP"
    }
  }
  depends_on = [ kubernetes_deployment.deploy ]
}

resource "kubernetes_ingress" "wordpress" {
  metadata {
    name      = "${var.wordpress.name}-ingress"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
    labels = var.wordpress.labels
  }

  spec {
    backend {
      service_name = kubernetes_service.wordpress.metadata[0].name
      service_port = kubernetes_service.wordpress.spec[0].port[0].port
    }
    rule {
      http {
        path {
          path = "/*"
          backend {
            service_name = kubernetes_service.wordpress.metadata[0].name
            service_port = kubernetes_service.wordpress.spec[0].port[0].port
          }
        }
      }
    }
  }
  depends_on = [ kubernetes_service.wordpress, helm_release.ingress-lb-controller ]
}

########################
## Output
########################
# output "load_balancer_hostname" {
#   value = kubernetes_ingress.wordpress.status.0.load_balancer.0.ingress.0.hostname
# }