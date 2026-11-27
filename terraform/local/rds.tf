resource "aws_db_instance" "main" {
  identifier        = "pasta-atlas-local"
  engine            = "postgres"
  engine_version    = "18"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  username = "pasta_atlas"
  password = var.db_password

  multi_az                = false
  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false
}
