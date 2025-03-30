provider "aws" {
  region = "us-east-1"
}


data "local_file" "basedata" {
  filename = "../base_data.txt"
}

data "local_file" "ami_ouput" {
  filename = "../ami_output.txt"
}

# Read VPC details from the output file
data "local_file" "vpc_output" {
  filename = "../vpc_output.txt"
}

# Extract VPC and Subnet IDs from the output file
locals {
  vpc_id                  = regex("vpc_id = (\\S+)", data.local_file.vpc_output.content)[0]
  public_subnet_1_id      = regex("public_subnet_1_id = (\\S+)", data.local_file.vpc_output.content)[0]
  public_subnet_2_id      = regex("public_subnet_2_id = (\\S+)", data.local_file.vpc_output.content)[0]
  private_subnet_1_id     = regex("private_subnet_1_id = (\\S+)", data.local_file.vpc_output.content)[0]
  private_subnet_2_id     = regex("private_subnet_2_id = (\\S+)", data.local_file.vpc_output.content)[0]
  security_group_id       = regex("sg1 = (\\S+)",  data.local_file.basedata.content)[0]
  ami_id                  = regex("ami_id = (\\S+)",  data.local_file.ami_ouput.content)[0]
}

#####################
# IAM Roles & Policies
#####################

# IAM Role for all Lambdas
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Policy for Lambda 1 & 2 (Full access to S3 & DynamoDB)
resource "aws_iam_policy" "lambda_s3_dynamodb_policy" {
  name        = "lambda_s3_dynamodb_policy"
  description = "Allow Lambda to access S3 & DynamoDB"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": "*"
    }
  ]
}
EOF
}

# Policy for Lambda 3 (Full access to S3, DynamoDB & SES)
resource "aws_iam_policy" "lambda_s3_dynamodb_ses_policy" {
  name        = "lambda_s3_dynamodb_ses_policy"
  description = "Allow Lambda to access S3, DynamoDB & SES"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::*"
    },
    {
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ses:*",
      "Resource": "*"
    }
  ]
}
EOF
}

# Policy for Lambda 4 (Invoke other Lambda functions)
resource "aws_iam_policy" "lambda_invoke_policy" {
  name        = "lambda_invoke_policy"
  description = "Allow Lambda to invoke other Lambda functions"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "lambda:InvokeFunction",
      "Resource": "*"
    }
  ]
}
EOF
}

# IAM Policy for Lambda1 to access SQS
resource "aws_iam_policy" "lambda_sqs_policy" {
  name        = "lambda_sqs_policy"
  description = "Allow Lambda1 to receive and delete messages from SQS"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility"
      ],
      "Resource": "${aws_sqs_queue.lambda1_queue.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_vpc_policy" {
  name   = "lambda_vpc_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach SQS Policy to Lambda1's IAM Role
resource "aws_iam_role_policy_attachment" "lambda1_sqs_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

# Attach Policies to Roles
resource "aws_iam_role_policy_attachment" "lambda1_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda2_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda3_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_s3_dynamodb_ses_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda4_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_invoke_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_vpc_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_vpc_policy.arn
}
#####################
# Create Lambda Functions
#####################
resource "aws_lambda_function" "lambda1" {
  function_name    = "lambda1"
  runtime         = "python3.10"
  handler         = "lambda_function.lambda_handler"
  role            = aws_iam_role.lambda_role.arn
  filename        = "lambda1.zip"
  source_code_hash = filebase64sha256("lambda1.zip")

  vpc_config {
    subnet_ids         = [local.public_subnet_1_id, local.public_subnet_2_id] # Replace with your subnet IDs
    security_group_ids = [local.security_group_id] # Replace with your security group ID
  }
}

resource "aws_lambda_function" "lambda2" {
  function_name    = "lambda2"
  runtime         = "python3.10"
  handler         = "lambda_function.lambda_handler"
  role            = aws_iam_role.lambda_role.arn
  filename        = "lambda2.zip"
  source_code_hash = filebase64sha256("lambda2.zip")

  vpc_config {
    subnet_ids         = [local.public_subnet_1_id, local.public_subnet_2_id] # Replace with your subnet IDs
    security_group_ids = [local.security_group_id] # Replace with your security group ID
  }
}

resource "aws_lambda_function" "lambda3" {
  function_name    = "lambda3"
  runtime         = "python3.10"
  handler         = "lambda_function.lambda_handler"
  role            = aws_iam_role.lambda_role.arn
  filename        = "lambda3.zip"
  source_code_hash = filebase64sha256("lambda3.zip")

  vpc_config {
    subnet_ids         = [local.public_subnet_1_id, local.public_subnet_2_id] # Replace with your subnet IDs
    security_group_ids = [local.security_group_id] # Replace with your security group ID
  }
}

resource "aws_lambda_function" "lambda4" {
  function_name    = "lambda4"
  runtime         = "python3.10"
  handler         = "lambda_function.lambda_handler"
  role            = aws_iam_role.lambda_role.arn
  filename        = "lambda4.zip"
  source_code_hash = filebase64sha256("lambda4.zip")

  vpc_config {
    subnet_ids         = [local.public_subnet_1_id, local.public_subnet_2_id] # Replace with your subnet IDs
    security_group_ids = [local.security_group_id] # Replace with your security group ID
  }
}

#####################
# CloudWatch Log Groups
#####################
resource "aws_cloudwatch_log_group" "lambda_log_group1" {
  name              = "/aws/lambda/lambda1"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_log_group2" {
  name              = "/aws/lambda/lambda2"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_log_group3" {
  name              = "/aws/lambda/lambda3"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "lambda_log_group4" {
  name              = "/aws/lambda/lambda4"
  retention_in_days = 14
}

#####################
# EventBridge Rule (Triggers Lambda4 every minute)
#####################
resource "aws_cloudwatch_event_rule" "lambda4_schedule" {
  name                = "lambda4-schedule"
  schedule_expression = "rate(1 minute)"
}

resource "aws_cloudwatch_event_target" "trigger_lambda4" {
  rule      = aws_cloudwatch_event_rule.lambda4_schedule.name
  arn       = aws_lambda_function.lambda4.arn
}

resource "aws_lambda_permission" "allow_eventbridge_lambda4" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda4.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda4_schedule.arn
}

#####################
# SQS Queue & Permission for Lambda1
#####################

# Create SQS Queue
resource "aws_sqs_queue" "lambda1_queue" {
  name = "lambda1-event-queue"
}

# SQS Permission to trigger Lambda1
resource "aws_lambda_event_source_mapping" "sqs_trigger_lambda1" {
  event_source_arn = aws_sqs_queue.lambda1_queue.arn
  function_name    = aws_lambda_function.lambda1.arn
  batch_size       = 1
}

resource "aws_lambda_permission" "allow_sqs_lambda1" {
  statement_id  = "AllowSQSTrigger"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda1.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.lambda1_queue.arn
}
