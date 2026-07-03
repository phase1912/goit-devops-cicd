variable "cluster_name" {
  type = string
}

variable "kaniko_role_arn" {
  type = string
}

variable "ecr_repository_url" {
  type = string
}

variable "chart_version" {
  type    = string
  default = "5.1.31"
}

variable "namespace" {
  type    = string
  default = "jenkins"
}
