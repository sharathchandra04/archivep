provider "aws" {
  region = "us-east-1"
}

#####################
# DynamoDB Tables
#####################

# Table: folders (user: int, folder: string)
resource "aws_dynamodb_table" "folders" {
  name         = "folders"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "user"
    type = "N" # Numeric (integer)
  }

  attribute {
    name = "folder"
    type = "S" # String
  }

  hash_key  = "user"   # Partition key
  range_key = "folder" # Sort key
}

# Table: myassets (id: string)
resource "aws_dynamodb_table" "myassets" {
  name         = "myassets"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S" # String
  }

  hash_key = "id" # Partition key
}

#####################
# Outputs (Print ARNs)
#####################

output "folders_table_arn" {
  value = aws_dynamodb_table.folders.arn
}

output "myassets_table_arn" {
  value = aws_dynamodb_table.myassets.arn
}

