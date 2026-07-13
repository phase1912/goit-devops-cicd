variable "use_aurora" {
  type        = bool
  description = "When true, creates Aurora cluster; when false, creates a standard RDS instance"
  default     = false
}

variable "engine" {
  type        = string
  description = "Database engine: postgres, mysql, aurora-postgresql, or aurora-mysql"
  default     = "postgres"
}

variable "engine_version" {
  type        = string
  description = "Engine version (major or full version, e.g. 15 or 15.4)"
  default     = "15"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class (e.g. db.t3.micro)"
  default     = "db.t3.micro"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment"
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the database will be deployed"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the DB subnet group"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to connect to the database"
  default     = []
}

variable "db_name" {
  type        = string
  description = "Name of the initial database"
  default     = "django"
}

variable "username" {
  type        = string
  description = "Master username for the database"
  default     = "dbadmin"
}

variable "password" {
  type        = string
  description = "Master password for the database"
  sensitive   = true
}

variable "identifier" {
  type        = string
  description = "Prefix for RDS resource names"
  default     = "lesson-db-module"
}
