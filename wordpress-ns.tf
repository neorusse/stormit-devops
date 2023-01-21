resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.wordpress.namespace
    labels = var.wordpress.labels
  }
}