provider "aws" {
  region = "us-east-1"
}

# Extract the VPC ID using regex
data "local_file" "vpc_output" {
  filename = "../vpc_output.txt"
}

# Extract VPC and Subnet IDs from the output file
locals {
  vpc_id = regex("vpc_id = (\\S+)", data.local_file.vpc_output.content)[0]
}

# Create a Security Group: sg1
resource "aws_security_group" "sg1" {
  name        = "sg1"
  description = "Security group with inbound rules for 5432, 22, and 5000"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create a Security Group: sgdb
resource "aws_security_group" "sgdb" {
  name        = "sgdb"
  description = "Security group with inbound rule for PostgreSQL (5432)"
  vpc_id      = local.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "aws_security_groupsgdbid" {
  value = aws_security_group.sg1.id
}

output "aws_security_groupsg1id" {
  value = aws_security_group.sgdb.id
}

# Update Security Group IDs in basedata.txt
resource "null_resource" "update_basedata" {
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = <<EOT
    sed -i "s/^sg1 = .*/sg1 = ${aws_security_group.sg1.id}/" ../base_data.txt
    sed -i "s/^sgdb = .*/sgdb = ${aws_security_group.sgdb.id}/" ../base_data.txt
    EOT
  }
}