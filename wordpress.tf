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

