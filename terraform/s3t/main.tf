provider "aws" {
  region = "us-east-1"
}

#####################
# S3 Buckets
#####################

# Main bucket
resource "aws_s3_bucket" "rscmainb" {
  bucket = "rscmainb"
}

# Archive bucket
resource "aws_s3_bucket" "rscarchiveb" {
  bucket = "rscarchiveb"
}

#####################
# Outputs (Print ARNs)
#####################

output "rscmainb_arn" {
  value = aws_s3_bucket.rscmainb.arn
}

output "rscarchiveb_arn" {
  value = aws_s3_bucket.rscarchiveb.arn
}

