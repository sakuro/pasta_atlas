data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.app_name}-${var.environment}"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_security_group" "rds" {
  name        = "${var.app_name}-${var.environment}-rds"
  description = "Allow PostgreSQL access from application servers"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "rds_from_app" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_security_group" "app" {
  name        = "${var.app_name}-${var.environment}-app"
  description = "Application server security group"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_db_instance" "main" {
  identifier        = "${var.app_name}-${var.environment}"
  engine            = "postgres"
  engine_version    = "18"
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = "pasta_atlas"
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az                = false
  backup_retention_period = 7
  skip_final_snapshot     = false
  final_snapshot_identifier = "${var.app_name}-${var.environment}-final"

  deletion_protection = true
}
