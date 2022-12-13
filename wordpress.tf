variable "wordpress" {}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.wordpress.namespace
    labels = var.wordpress.labels
  }
}

resource "kubernetes_deployment" "deploy" {
  metadata {
    name      = var.wordpress.name
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels    = var.wordpress.labels
  }

  spec {
    replicas = var.wordpress.replicas

    selector {
      match_labels = var.wordpress.labels
    }

    template {
      metadata {
        labels = var.wordpress.labels
      }

      spec {
        container {
          image = "wordpress"
          name  = "wordpress"
          port   {
              name = "wordpress"
              container_port = 80
          }
          volume_mount  {
              name = "wp-pv-storage"
              mount_path = "/var/www/html"
          }
          env {
            name = "DB_HOST"
            value = var.wordpress.db_host
          }
          env { 
            name = "DB_USER"
            value = var.wordpress.db_user
          }
          env { 
            name = "DB_PASSWORD"
            value = var.wordpress.db_password 
          } 
          env {
            name = "DB_NAME"
            value = var.wordpress.db_name
          }
        }
        volume  {
          name = "wp-pv-storage"
          persistent_volume_claim { 
              claim_name = kubernetes_persistent_volume_claim.wordpress.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "wordpress" {
  metadata {
    name = "${var.wordpress.name}-pvc"
    namespace = kubernetes_namespace.namespace.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = kubernetes_storage_class.wordpress.metadata[0].name
    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
  depends_on = [ kubernetes_persistent_volume.wordpress ]
}

resource "kubernetes_service" "wordpress" {
  metadata {
    name = "${var.wordpress.name}-service"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    /*annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb-ip"
    }*/
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
  wait_for_load_balancer = true
  depends_on = [ kubernetes_service.wordpress]
}

