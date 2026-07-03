resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_account" "kaniko" {
  metadata {
    name      = "kaniko"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = var.kaniko_role_arn
    }
  }
}

resource "kubernetes_role" "jenkins_agent" {
  metadata {
    name      = "jenkins-agent"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/exec", "pods/log", "persistentvolumeclaims", "events"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }

  rule {
    api_groups = [""]
    resources  = ["secrets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups     = [""]
    resources      = ["serviceaccounts"]
    resource_names = ["kaniko"]
    verbs          = ["use"]
  }
}

resource "kubernetes_role_binding" "jenkins_agent" {
  metadata {
    name      = "jenkins-agent"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.jenkins_agent.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "jenkins"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }
}

resource "helm_release" "jenkins" {
  name       = "jenkins"
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name
  version    = var.chart_version
  timeout    = 1200

  values = [file("${path.module}/values.yaml")]

  depends_on = [
    kubernetes_service_account.kaniko,
    kubernetes_role_binding.jenkins_agent,
  ]
}
