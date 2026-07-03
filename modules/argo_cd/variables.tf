variable "repo_url" {
  type = string
}

variable "chart_path" {
  type = string
}

variable "target_revision" {
  type    = string
  default = "master"
}

variable "app_name" {
  type    = string
  default = "django-app"
}

variable "app_namespace" {
  type    = string
  default = "django"
}

variable "namespace" {
  type    = string
  default = "argocd"
}

variable "chart_version" {
  type    = string
  default = "7.3.11"
}
