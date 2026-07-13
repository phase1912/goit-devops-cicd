variable "use_aurora" {
  type        = bool
  description = "When true, deploy Aurora cluster; when false, deploy standard RDS instance"
  default     = false
}

variable "db_engine" {
  type        = string
  description = "Database engine: postgres or mysql (auto-mapped to Aurora when use_aurora is true)"
  default     = "postgres"
}

variable "db_engine_version" {
  type        = string
  description = "Database engine version"
  default     = "15"
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_multi_az" {
  type        = bool
  description = "Enable Multi-AZ for RDS instance"
  default     = false
}

variable "db_username" {
  type        = string
  description = "Master database username"
  default     = "dbadmin"
}

variable "db_password" {
  type        = string
  description = "Master database password"
  sensitive   = true
}
