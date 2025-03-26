provider "aws" {
  region = "us-east-1" # Adjust to your region
}

data "local_file" "basedata" {
  filename = "../base_data.txt"
}

data "local_file" "ami_ouput" {
  filename = "../ami_output.txt"
}

# Read VPC details from the output file
data "local_file" "vpc_output" {
  filename = "vpc_output.txt"
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
# Load Balancer
#####################
resource "aws_lb" "my_lb" {
  name               = "my-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [local.security_group_id] # Using security group from the output file
  subnets            = [local.public_subnet_1_id, local.public_subnet_2_id]  # Using public subnets from the output file

  enable_deletion_protection        = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "MyLoadBalancer"
  }
}

#####################
# Target Group (for Load Balancer)
#####################
resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id  # Using VPC ID from the output file

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "MyTargetGroup"
  }
}

#####################
# Listener for Load Balancer
#####################
resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    type             = "forward"
  }
}

#####################
# Launch Configuration (Using Hardcoded AMI)
#####################
resource "aws_launch_configuration" "my_launch_config" {
  name          = "my-launch-config"
  image_id      = local.ami_id # Replace with your hardcoded AMI ID
  instance_type = "t2.micro" # Replace with your desired instance type

  lifecycle {
    create_before_destroy = true
  }

  security_groups = [local.security_group_id] # Using security group from the output file

  user_data = <<-EOF
              #!/bin/bash
              # Add any user data scripts you want to run on instance startup
              cd archivep
              cd backend
              source devenv.sh
              flask --app=./app:app db migrate
              flask --app=./app:app db upgrade
              Start the Flask server
              echo "Starting Flask server..."
              python app.py
              EOF
}

#####################
# Auto Scaling Group
#####################
resource "aws_autoscaling_group" "my_asg" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = [local.public_subnet_1_id, local.public_subnet_2_id] # Using public subnets from the output file
  launch_configuration = aws_launch_configuration.my_launch_config.id
  target_group_arns    = [aws_lb_target_group.my_target_group.arn]

  health_check_type          = "ELB"
  health_check_grace_period = 300
  wait_for_capacity_timeout  = "0"

  tag {
    key                 = "Name"
    value               = "MyAutoScalingGroupInstance"
    propagate_at_launch = true
  }
}

#####################
# Output ARNs
#####################
output "load_balancer_arn" {
  value = aws_lb.my_lb.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.my_target_group.arn
}

output "auto_scaling_group_arn" {
  value = aws_autoscaling_group.my_asg.arn
}
