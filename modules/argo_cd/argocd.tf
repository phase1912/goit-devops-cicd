resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.namespace
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  version    = var.chart_version
  timeout    = 1200

  values = [file("${path.module}/values.yaml")]
}

resource "helm_release" "argocd_apps" {
  name      = "argocd-apps"
  chart     = "${path.module}/charts"
  namespace = kubernetes_namespace.argocd.metadata[0].name
  timeout   = 600

  values = [
    yamlencode({
      app = {
        name           = var.app_name
        repoURL        = var.repo_url
        targetRevision = var.target_revision
        chartPath      = var.chart_path
        namespace      = var.app_namespace
      }
    })
  ]

  depends_on = [helm_release.argocd]

  wait = true
}
