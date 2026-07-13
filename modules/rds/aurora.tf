resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier              = var.identifier
  engine                          = local.effective_engine
  engine_version                  = var.engine_version
  database_name                   = var.db_name
  master_username                 = var.username
  master_password                 = var.password
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.db.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this[0].name
  storage_encrypted               = true
  backup_retention_period         = var.backup_retention_period
  skip_final_snapshot             = true

  tags = {
    Name = var.identifier
  }
}

resource "aws_rds_cluster_instance" "writer" {
  count = var.use_aurora ? 1 : 0

  identifier         = "${var.identifier}-writer"
  cluster_identifier = aws_rds_cluster.this[0].id
  instance_class     = var.instance_class
  engine             = local.effective_engine
  engine_version     = var.engine_version
  promotion_tier     = 0

  tags = {
    Name = "${var.identifier}-writer"
  }
}

resource "aws_rds_cluster_instance" "readers" {
  count = var.use_aurora ? var.reader_count : 0

  identifier         = "${var.identifier}-reader-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this[0].id
  instance_class     = var.instance_class
  engine             = local.effective_engine
  engine_version     = var.engine_version
  promotion_tier     = count.index + 1

  tags = {
    Name = "${var.identifier}-reader-${count.index + 1}"
  }
}
