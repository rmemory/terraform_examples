# A load balancer routes traffic to target groups. A target group can be a 
# group of EC2 instances, lambdas, or IP addresses. It can also carry out 
# health checks.
# This ALB will have two listeners: one on port 80 and one on port 443. 
# Requests on port 80 will be redirected to 443. Requests on 443 will be validated
# against the certificate.
resource "aws_lb" "application_lb" {
  provider           = aws.us-east-1
  internal           = false #Internal load balancers are only available internal to the VPC
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.primary_subnet_public_1.id, aws_subnet.primary_subnet_public_2.id] # Connect LB to two subnets for high availability
  tags = {
    Name = "jenkins_alb"
  }
}

# A target group resource is the interface between the load balancer and the 
# instances (via a target group attachment defined below)
# Make sure the security group for the EC2 allows traffic on the var.application-port
resource "aws_lb_target_group" "alb_tg" {
  provider    = aws.us-east-1
  port        = var.application_port # Port application in EC2 is running on
  target_type = "instance"
  vpc_id      = aws_vpc.primary.id
  protocol    = "HTTP"
  health_check {
    enabled  = true
    interval = 10 # seconds
    path     = "/"
    port     = var.application_port # Port to application and application security group
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    Name = "jenkins_alb_target_group"
  }
}

# A listener is a resource that sits in front of the load balancer and checks 
# for connection requests from the internet using the protocol and port that 
# you configure. The rules that you define for a listener determine how the 
# load balancer routes requests to its registered targets.
resource "aws_lb_listener" "http" {
  provider          = aws.us-east-1
  load_balancer_arn = aws_lb.application_lb.arn # Tie listener to the load balancer
  port              = "80"                      # incoming requests from the internet
  protocol          = "HTTP"
  default_action {
    # type             = "forward"
    # target_group_arn = aws_lb_target_group.alb_tg.id
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" # 301 is a permanent redirect
    }
  }
}

#Create new listener on tcp/443 HTTPS
resource "aws_lb_listener" "https" {
  provider          = aws.us-east-1
  load_balancer_arn = aws_lb.application_lb.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.cert.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_tg.arn # Target group attached to load balancer
  }
}

# Attach the EC2 isntance to the target group (one attachment per EC2)
resource "aws_lb_target_group_attachment" "jenkins_master_instance_attach" {
  provider         = aws.us-east-1
  target_group_arn = aws_lb_target_group.alb_tg.arn
  target_id        = aws_instance.jenkins_primary.id
  port             = var.application_port
}
