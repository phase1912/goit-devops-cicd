data "kubernetes_secret" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = var.namespace
  }

  depends_on = [helm_release.jenkins]
}

data "kubernetes_service" "jenkins" {
  metadata {
    name      = "jenkins"
    namespace = var.namespace
  }

  depends_on = [helm_release.jenkins]
}

output "jenkins_url" {
  value = try(
    "http://${data.kubernetes_service.jenkins.status[0].load_balancer[0].ingress[0].hostname}:8080",
    "pending"
  )
}

output "admin_password" {
  value = data.kubernetes_secret.jenkins.data["jenkins-admin-password"]
}
