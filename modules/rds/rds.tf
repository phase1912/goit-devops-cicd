resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier             = var.identifier
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = 20
  storage_type           = "gp2"
  db_name                = var.db_name
  username               = var.username
  password               = var.password
  multi_az               = var.multi_az
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  parameter_group_name   = aws_db_parameter_group.this[0].name
  skip_final_snapshot    = true
  publicly_accessible    = false

  tags = {
    Name = var.identifier
  }
}
