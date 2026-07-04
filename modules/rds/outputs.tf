output "db_endpoint" {
  description = "Database endpoint hostname"
  value       = var.use_aurora ? aws_rds_cluster.this[0].endpoint : aws_db_instance.this[0].address
}

output "db_port" {
  description = "Database port"
  value       = local.db_port
}

output "db_name" {
  description = "Database name"
  value       = var.db_name
}

output "db_mode" {
  description = "Deployment mode: aurora or rds"
  value       = var.use_aurora ? "aurora" : "rds"
}

output "security_group_id" {
  description = "Security group ID attached to the database"
  value       = aws_security_group.db.id
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.this.name
}

output "parameter_group_name" {
  description = "Parameter group name (RDS or Aurora cluster)"
  value       = var.use_aurora ? aws_rds_cluster_parameter_group.this[0].name : aws_db_parameter_group.this[0].name
}

output "db_arn" {
  description = "ARN of the database (instance or cluster)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].arn : aws_db_instance.this[0].arn
}

output "reader_endpoint" {
  description = "Aurora cluster reader endpoint (empty for RDS instance mode)"
  value       = var.use_aurora ? aws_rds_cluster.this[0].reader_endpoint : null
}
