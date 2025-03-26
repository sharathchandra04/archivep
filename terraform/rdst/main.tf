provider "aws" {
  region = "us-east-1"
}

#####################
# Secure Credentials (Avoid Hardcoding)
#####################
variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "mydatabase"
}

#####################
# RDS PostgreSQL Instance
#####################
resource "aws_db_instance" "postgres_rds" {
  identifier           = "mypostgres-db"
  engine              = "postgres"
  engine_version      = "15.3"
  instance_class      = "db.t3.micro"
  allocated_storage   = 20
  max_allocated_storage = 100
  storage_type        = "gp2"

  db_name             = var.db_name
  username           = var.db_username
  password           = var.db_password
  parameter_group_name = "default.postgres15"
  
  publicly_accessible = false
  skip_final_snapshot = true

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
}

#####################
# Security Group for RDS
#####################
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow inbound traffic for PostgreSQL"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Change to restrict access
  }
}

#####################
# Outputs (Print ARNs)
#####################
output "rds_instance_arn" {
  value = aws_db_instance.postgres_rds.arn
}

output "rds_endpoint" {
  value = aws_db_instance.postgres_rds.endpoint
}

