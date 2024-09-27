# Generate a random password for the Aurora PostgreSQL master user
resource "random_password" "master_password" {
  length  = 16
  special = false
}

# Store the generated password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_master_password" {
  name                    = "aurora-db-master-password"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_master_password_version" {
  secret_id     = aws_secretsmanager_secret.db_master_password.id
  secret_string = random_password.master_password.result
}

# Aurora PostgreSQL Database
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier           = "tppb${var.environment}"
  engine                       = "aurora-postgresql"
  engine_version               = "13.12"
  database_name                = "tppb${var.environment}"
  master_username              = "root"
  master_password              = aws_secretsmanager_secret_version.db_master_password_version.secret_string
  skip_final_snapshot          = true
  engine_mode                  = "serverless"
  vpc_security_group_ids       = [aws_security_group.aurora_sg.id]
  db_subnet_group_name         = aws_db_subnet_group.aurora_subnet_group.name
  apply_immediately            = true
  backup_retention_period      = 1
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "Mon:04:30-Mon:05:30" # Ensure this doesn't overlap with backup_window

  scaling_configuration {
    auto_pause   = false
    max_capacity = var.max_capacity
    min_capacity = 2
  }
}

# # Instance attached to the Aurora PostgreSQL cluster
# resource "aws_rds_cluster_instance" "aurora_instance" {
#   identifier         = "tppb-instance-${var.environment}"
#   cluster_identifier = aws_rds_cluster.aurora_cluster.id
#   instance_class     = "db.serverless"
#   engine             = "aurora-postgresql"
#   engine_version     = "16.1"
# }

resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = [aws_subnet.private1.id, aws_subnet.private2.id]
}
