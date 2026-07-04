locals {
  is_postgres = contains(["postgres", "aurora-postgresql"], var.engine)

  effective_engine = var.use_aurora ? (
    var.engine == "postgres" ? "aurora-postgresql" :
    var.engine == "mysql" ? "aurora-mysql" : var.engine
  ) : var.engine

  major_version = split(".", var.engine_version)[0]

  parameter_family = var.use_aurora ? (
    local.is_postgres ? "aurora-postgresql${local.major_version}" : "aurora-mysql8.0"
    ) : (
    local.is_postgres ? "postgres${local.major_version}" : "mysql8.0"
  )

  db_port = local.is_postgres ? 5432 : 3306

  postgres_parameters = [
    { name = "max_connections", value = "100", apply_method = "pending-reboot" },
    { name = "log_statement", value = "all", apply_method = "immediate" },
    { name = "work_mem", value = "4096", apply_method = "immediate" },
  ]

  mysql_parameters = [
    { name = "max_connections", value = "100", apply_method = "pending-reboot" },
    { name = "general_log", value = "1", apply_method = "immediate" },
    { name = "innodb_buffer_pool_size", value = "{DBInstanceClassMemory*3/4}", apply_method = "pending-reboot" },
  ]

  db_parameters = local.is_postgres ? local.postgres_parameters : local.mysql_parameters
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.identifier}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = {
    Name = "${var.identifier}-subnet-group"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.identifier}-db-sg"
  description = "Security group for ${var.identifier} database"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.identifier}-db-sg"
  }
}

resource "aws_db_parameter_group" "this" {
  count  = var.use_aurora ? 0 : 1
  name   = "${var.identifier}-pg"
  family = local.parameter_family

  dynamic "parameter" {
    for_each = local.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = {
    Name = "${var.identifier}-pg"
  }
}

resource "aws_rds_cluster_parameter_group" "this" {
  count  = var.use_aurora ? 1 : 0
  name   = "${var.identifier}-cluster-pg"
  family = local.parameter_family

  dynamic "parameter" {
    for_each = local.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = {
    Name = "${var.identifier}-cluster-pg"
  }
}
