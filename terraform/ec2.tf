provider "aws" {
  region = "us-east-1"  # Replace with your preferred region
}

# Step 1: Create Security Groups

# Security Group for the Load Balancer
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP traffic to the ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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

# Security Group for EC2 Instances
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow HTTP and custom port (5000) traffic to the EC2 instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
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

# Step 2: Create the Application Load Balancer (ALB)
resource "aws_lb" "alb" {
  name               = "example-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "example-alb"
  }
}

# Step 3: Create a Target Group for the ALB
resource "aws_lb_target_group" "target_group" {
  name     = "example-target-group"
  port     = 5000  # Forward traffic to port 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "example-target-group"
  }
}

# Step 4: Create a Listener for the ALB to Forward to Port 5000
resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Step 5: Launch Template for Auto Scaling Group
resource "aws_launch_template" "ubuntu_launch_template" {
  name_prefix   = "ubuntu-template"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"  # You can change the instance type as needed
  security_group_names = [aws_security_group.ec2_sg.name]

  user_data = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y apache2
    apt-get install -y python3-pip
    pip3 install flask
    echo "from flask import Flask
app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello, World from Flask on Port 5000!' 

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)" > /home/ubuntu/app.py
    nohup python3 /home/ubuntu/app.py &
  EOT
}

# Step 6: Create the Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
  launch_template {
    id      = aws_launch_template.ubuntu_launch_template.id
    version = "$Latest"
  }
  health_check_type    = "EC2"
  health_check_grace_period = 300
  force_delete         = true
  wait_for_capacity_timeout = "0"

  tag {
    key                 = "Name"
    value               = "Ubuntu-EC2-Instance"
    propagate_at_launch = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}

# Step 7: Data source to fetch the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Ubuntu's official AWS account
  filters = {
    name = "ubuntu/images/hvm-ssd/ubuntu*-*-amd64-server-*"
  }
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "auto_scaling_group_name" {
  value = aws_autoscaling_group.asg.name
}
