provider "aws" {
  region = "us-east-1"
}

# Reading base data and ami output files
data "local_file" "basedata" {
  filename = "../base_data.txt"
}

data "local_file" "ami_output" {
  filename = "../ami_output.txt"
}

# Reading VPC details from the output file
data "local_file" "vpc_output" {
  filename = "../vpc_output.txt"
}

# Extract VPC and Subnet IDs, and other information using regex
locals {
  vpc_id                  = regex("vpc_id = (\\S+)", data.local_file.vpc_output.content) != [] ? regex("vpc_id = (\\S+)", data.local_file.vpc_output.content)[0] : null
  public_subnet_1_id      = regex("public_subnet_1_id = (\\S+)", data.local_file.vpc_output.content) != [] ? regex("public_subnet_1_id = (\\S+)", data.local_file.vpc_output.content)[0] : null
  public_subnet_2_id      = regex("public_subnet_2_id = (\\S+)", data.local_file.vpc_output.content) != [] ? regex("public_subnet_2_id = (\\S+)", data.local_file.vpc_output.content)[0] : null
  private_subnet_1_id     = regex("private_subnet_1_id = (\\S+)", data.local_file.vpc_output.content) != [] ? regex("private_subnet_1_id = (\\S+)", data.local_file.vpc_output.content)[0] : null
  private_subnet_2_id     = regex("private_subnet_2_id = (\\S+)", data.local_file.vpc_output.content) != [] ? regex("private_subnet_2_id = (\\S+)", data.local_file.vpc_output.content)[0] : null
  security_group_id       = regex("sgdb = (\\S+)", data.local_file.basedata.content) != [] ? regex("sgdb = (\\S+)", data.local_file.basedata.content)[0] : null
  ami_id                  = regex("ami_id = (\\S+)", data.local_file.ami_output.content) != [] ? regex("ami_id = (\\S+)", data.local_file.ami_output.content)[0] : null
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

resource "aws_db_instance" "postgres_rds" {
  identifier            = "mypostgres-db"
  engine                = "postgres"
  engine_version        = "15.9"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp2"

  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.postgres15"
  
  publicly_accessible  = true
  skip_final_snapshot  = true
  
  vpc_security_group_ids = [local.security_group_id]
  db_subnet_group_name   = aws_db_subnet_group.postgres_subnet_group.name

  # VPC Configuration (VPC and Subnet)
  availability_zone     = "us-east-1a"
  multi_az              = false
}

########################
# Security Group for RDS
########################
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Allow inbound traffic for PostgreSQL"

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#####################
# DB Subnet Group for RDS
#####################
resource "aws_db_subnet_group" "postgres_subnet_group" {
  name        = "postgres-subnet-group"
  description = "Subnet group for RDS PostgreSQL instance"
  subnet_ids  = [local.public_subnet_1_id, local.public_subnet_2_id]
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
