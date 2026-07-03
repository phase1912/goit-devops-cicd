output "s3_bucket_url" {
  value = module.s3_backend.bucket_url
}

output "dynamodb_table_name" {
  value = module.s3_backend.dynamodb_table_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region us-west-2 --name ${module.eks.cluster_name}"
}

output "jenkins_url" {
  value = module.jenkins.jenkins_url
}

output "jenkins_admin_password" {
  value     = module.jenkins.admin_password
  sensitive = true
}

output "argocd_url" {
  value = module.argo_cd.argocd_url
}

output "argocd_admin_password" {
  value     = module.argo_cd.admin_password
  sensitive = true
}
