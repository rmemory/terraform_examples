#
# Get a list of AMIs from SSM
#

# https://medium.com/@endofcake/using-terraform-for-zero-downtime-updates-of-an-auto-scaling-group-in-aws-60faca582664

# https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/
# Get Linux AMI ID using SSM Parameter endpoint in us-east-1
# aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn*" --query 'sort_by(Images, &CreationDate)[].Name'
# aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1 
# Data sources are called first before provisioning
data "aws_ssm_parameter" "linuxAmi" {
  provider = aws.default-provider
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Create the private/public key pair prior to creation of EC2.
#
# AWS requires keys that are RSA 1048 bit keys, compatible with version 2 
# protocol of openssh.
#
# $ ssh-keygen -t rsa
# ls ~/.ssh/id_rsa
# ls ~/.ssh/id_rsa.pub

# Please note that this code expects SSH key pair to exist in default dir under
# the users home directory, otherwise it will fail.

# Keys are regional

#Create key-pair for logging into EC2
resource "aws_key_pair" "master-key" {
  provider   = aws.default-provider
  key_name   = "instance_key_pair"
  public_key = file("~/.ssh/id_rsa.pub") # file on localhost
}

# Create and bootstrap EC2s 
# resource "aws_instance" "instances" {
#   provider                    = aws.default-provider
#   count                       = 1
#   ami                         = data.aws_ssm_parameter.linuxAmi.value
#   instance_type               = var.instance-type
#   key_name                    = aws_key_pair.master-key.key_name
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.dmz-sg.id, aws_security_group.web-sg.id]
#   subnet_id                   = aws_subnet.public-1.id

#   user_data = <<-EOF
#               #!/bin/bash
#               sudo yum update -y
#               sudo yum install -y httpd
#               sudo echo "Hello world" > /var/www/html/index.html
#               sudo systemctl start httpd
#               sudo systemctl enable httpd
#               EOF

#   tags = {
#     Name = join("_", ["instance", count.index + 1])
#   }

#    depends_on = [aws_main_route_table_association.route-association]
# }

#
# Autoscaling group and launch configuration
#
resource "aws_launch_configuration" "launch_cfg" {
  provider        = aws.default-provider
  image_id        = data.aws_ssm_parameter.linuxAmi.value
  instance_type   = var.instance-type
  security_groups = [aws_security_group.dmz-sg.id, aws_security_group.web-sg.id]
  user_data       = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y httpd
              sudo echo "Hello world" > /var/www/html/index.html
              sudo systemctl start httpd
              sudo systemctl enable httpd
              EOF
}

# List of public subnets
data "aws_subnet_ids" "public" {
  provider = aws.default-provider
  vpc_id   = aws_vpc.vpc.id
  tags = {
    Tier = "Public"
  }
  depends_on = [aws_main_route_table_association.route-association]
}

resource "aws_autoscaling_group" "asg" {
  provider             = aws.default-provider
  launch_configuration = aws_launch_configuration.launch_cfg.name
  target_group_arns    = [aws_lb_target_group.app-lb-tg.arn]
  health_check_type    = "ELB"
  vpc_zone_identifier  = data.aws_subnet_ids.public.ids
  min_size             = 2
  max_size             = 5
  desired_capacity     = 2

  # Required when using a launch config with an asg
  lifecycle {
    create_before_destroy = true
  }
}

#
# Load balancer
#
resource "aws_lb" "lb" {
  provider           = aws.default-provider
  name               = "load-balancer"
  load_balancer_type = "application"
  subnets            = data.aws_subnet_ids.public.ids
  security_groups    = [aws_security_group.lb-sg.id]
}

resource "aws_lb_listener" "http" {
  provider          = aws.default-provider
  load_balancer_arn = aws_lb.lb.arn
  port              = var.application_port
  protocol          = "HTTP"

  # default_action {
  #   type             = "forward"
  #   target_group_arn = aws_lb_target_group.app-lb-tg.arn
  # }

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "lb_listener_rule" {
  provider     = aws.default-provider
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-lb-tg.arn
  }
}

# A target group resource is the interface between the load balancer and the 
# EC2s launched by the ASG.
# Make sure the security group for the EC2 allows traffic on the var.server_port
resource "aws_lb_target_group" "app-lb-tg" {
  provider = aws.default-provider
  name     = "app-lb-tg"
  port     = var.server_port # The port application is running on EC2s

  # target_type = "instance" # Only used of target group points at fixed list of EC2s.
  vpc_id   = aws_vpc.vpc.id
  protocol = "HTTP"

  health_check {
    enabled             = true
    interval            = 10 # seconds
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
    path                = "/"
    port                = var.server_port # Port to application and application security group
    protocol            = "HTTP"
    matcher             = "200-299"
  }
  tags = {
    Name = "target-group"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment" {
  provider               = aws.default-provider
  autoscaling_group_name = aws_autoscaling_group.asg.id
  alb_target_group_arn   = aws_lb_target_group.app-lb-tg.arn
}

# 
# Security Groups
#
resource "aws_security_group" "web-sg" {
  provider    = aws.default-provider
  name        = "web-sg"
  description = "Allow HTTP on TCP/application port"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description     = "Allow application port access from any IP"
    from_port       = var.server_port
    to_port         = var.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb-sg.id]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb-sg" {
  provider    = aws.default-provider
  name        = "lb-sg"
  description = "Allow HTTP on TCP/application port"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "Allow application port access from any IP"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output alb_dns_name {
  value       = aws_lb.lb.dns_name
  description = "The domain name of the load balancer"
}
