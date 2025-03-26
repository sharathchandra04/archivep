provider "aws" {
  region = "us-east-1" # Adjust to your region
}

#####################
# Load Balancer
#####################
resource "aws_lb" "my_lb" {
  name               = "my-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [] # Add your security groups here
  subnets            = [
    # Add the subnet IDs for your VPC here
    "subnet-xxxxxxxx", # Replace with your subnet ID
    "subnet-yyyyyyyy"  # Replace with your subnet ID
  ]

  enable_deletion_protection = false
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
  vpc_id   = "vpc-xxxxxxxx" # Replace with your VPC ID

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
  image_id      = "ami-xxxxxxxxxxxxxxxxx" # Replace with your hardcoded AMI ID
  instance_type = "t2.micro" # Replace with your desired instance type

  lifecycle {
    create_before_destroy = true
  }

  security_groups = [] # Add your security groups here

  user_data = <<-EOF
              #!/bin/bash
              # Add any user data scripts you want to run on instance startup
              EOF
}

#####################
# Auto Scaling Group
#####################
resource "aws_autoscaling_group" "my_asg" {
  desired_capacity     = 2
  max_size             = 5
  min_size             = 1
  vpc_zone_identifier  = ["subnet-xxxxxxxx", "subnet-yyyyyyyy"] # Replace with your subnet IDs
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
