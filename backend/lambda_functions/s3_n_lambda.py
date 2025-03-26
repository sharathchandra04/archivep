provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# 1. Create 2 S3 Buckets
resource "aws_s3_bucket" "bucket1" {
  bucket = "my-s3-bucket-1"  # Make sure the bucket name is globally unique
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "my-s3-bucket-2"  # Make sure the bucket name is globally unique
}

# 2. Create IAM Role for Lambda Functions
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

# 3. IAM Policy for Lambda to read and write from S3 Buckets
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "lambda_s3_policy"
  description = "Policy for Lambda to read and write from S3 Buckets"
  policy      = data.aws_iam_policy_document.lambda_s3_policy.json
}

# Attach the IAM policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_s3_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# 4. Create Lambda Function 1 (f1)
resource "aws_lambda_function" "f1" {
  function_name = "f1"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"  # Change this to your runtime
  filename      = "f1.zip"      # Path to the Lambda function zip file

  environment {
    variables = {
      S3_BUCKET_1 = aws_s3_bucket.bucket1.bucket
      S3_BUCKET_2 = aws_s3_bucket.bucket2.bucket
    }
  }
}

# 5. Create Lambda Function 2 (f2)
resource "aws_lambda_function" "f2" {
  function_name = "f2"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"  # Change this to your runtime
  filename      = "f2.zip"      # Path to the Lambda function zip file

  environment {
    variables = {
      S3_BUCKET_1 = aws_s3_bucket.bucket1.bucket
      S3_BUCKET_2 = aws_s3_bucket.bucket2.bucket
    }
  }
}

# Data sources for IAM policy documents

# 6. IAM Assume Role Policy for Lambda
data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 7. IAM Policy Document for Lambda to Access S3 Buckets
data "aws_iam_policy_document" "lambda_s3_policy" {
  statement {
    actions = ["s3:GetObject", "s3:PutObject"]
    resources = [
      "${aws_s3_bucket.bucket1.arn}/*",
      "${aws_s3_bucket.bucket2.arn}/*"
    ]
  }
}
