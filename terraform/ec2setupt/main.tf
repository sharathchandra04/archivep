provider "aws" {
  region = "us-east-1" # Adjust to your region
}

data "local_file" "basedata" {
  filename = "../base_data.txt"
}

data "local_file" "ami_ouput" {
  filename = "../ami_output.txt"
}

data "local_file" "vpc_output" {
  filename = "../vpc_output.txt"
}

locals {
  vpc_id                  = regex("vpc_id = (\\S+)", data.local_file.vpc_output.content)[0]
  public_subnet_1_id      = regex("public_subnet_1_id = (\\S+)", data.local_file.vpc_output.content)[0]
  public_subnet_2_id      = regex("public_subnet_2_id = (\\S+)", data.local_file.vpc_output.content)[0]
  private_subnet_1_id     = regex("private_subnet_1_id = (\\S+)", data.local_file.vpc_output.content)[0]
  private_subnet_2_id     = regex("private_subnet_2_id = (\\S+)", data.local_file.vpc_output.content)[0]
  security_group_id       = regex("sg1 = (\\S+)",  data.local_file.basedata.content)[0]
  ami_id                  = regex("ami_id = (\\S+)",  data.local_file.ami_ouput.content)[0]
}

resource "aws_lb" "my_lb" {
  name               = "my-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [local.security_group_id]
  subnets            = [local.public_subnet_1_id, local.public_subnet_2_id]

  enable_deletion_protection        = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "MyLoadBalancer"
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = local.vpc_id

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

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    type             = "forward"
  }
}

resource "aws_launch_template" "my_launch_template" {
  name          = "my-launch-template"
  image_id      = local.ami_id
  instance_type = "t2.micro"
  key_name      = "malcom1"
  vpc_security_group_ids = [local.security_group_id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo apt install nginx -y
              sudo systemctl start nginx
              sudo systemctl enable nginx
              cd archivep
              source venv/bin/activate
              cd backend
              source ../../prodenv.sh
              echo "Starting Flask server..."
              flask --app=./app:app db migrate
              flask --app=./app:app db upgrade
              python app.py
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "MyInstance"
    }
  }
}

resource "aws_autoscaling_group" "my_asg" {
  desired_capacity     = 1
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [local.public_subnet_1_id, local.public_subnet_2_id]

  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }

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

output "load_balancer_arn" {
  value = aws_lb.my_lb.arn
}

output "target_group_arn" {
  value = aws_lb_target_group.my_target_group.arn
}

output "auto_scaling_group_arn" {
  value = aws_autoscaling_group.my_asg.arn
}
