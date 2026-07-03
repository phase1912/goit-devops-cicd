data "kubernetes_secret" "argocd" {
  metadata {
    name      = "argocd-initial-admin-secret"
    namespace = var.namespace
  }

  depends_on = [helm_release.argocd]
}

data "kubernetes_service" "argocd" {
  metadata {
    name      = "argocd-server"
    namespace = var.namespace
  }

  depends_on = [helm_release.argocd]
}

output "argocd_url" {
  value = try(
    "http://${data.kubernetes_service.argocd.status[0].load_balancer[0].ingress[0].hostname}",
    "pending"
  )
}

output "admin_password" {
  value = data.kubernetes_secret.argocd.data["password"]
}
