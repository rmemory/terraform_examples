resource "aws_security_group" "lb-sg" {
  provider    = aws.region-default
  name        = "lb-sg"
  description = "Allow 443 and http traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow 443 from anywhere (forwarded to application port on master-sg)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow 80 from anywhere for redirection"
    from_port   = 80
    to_port     = 80
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


# A load balancer routes traffic to target groups. A target group can be a 
# group of EC2 instances, lambdas, or IP addresses. It can also carry out 
# health checks.
# This ALB will have two listeners: one on port 80 and one on port 443. 
# Requests on port 80 will be redirected to 443. Requests on 443 will be validated
# against the certificate.
resource "aws_lb" "application-lb" {
  provider           = aws.region-master
  name               = "jenkins-lb"
  internal           = false #Internal load balancers are only available internal to the VPC
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg.id]
  subnets            = [aws_subnet.master-subnet-public-1.id, aws_subnet.master-subnet-public-2.id] # Connect LB to two subnets for high availability
  tags = {
    Name = "Jenkins-LB"
  }
}

# A target group resource is the interface between the load balancer and the 
# instances (via a target group attachment defined below)
# Make sure the security group for the EC2 allows traffic on the var.application-port
resource "aws_lb_target_group" "app-lb-tg" {
  provider    = aws.region-master
  name        = "app-lb-tg"
  port        = var.application-port # Port application in EC2 is running on
  target_type = "instance"
  vpc_id      = aws_vpc.master.id
  protocol    = "HTTP"
  health_check {
    enabled  = true
    interval = 10 # seconds
    path     = "/"
    port     = var.application-port # Port to application and application security group
    protocol = "HTTP"
    matcher  = "200-299"
  }
  tags = {
    Name = "jenkins-target-group"
  }
}

# A listener is a resource that sits in front of the load balancer and checks 
# for connection requests from the internet using the protocol and port that 
# you configure. The rules that you define for a listener determine how the 
# load balancer routes requests to its registered targets.
resource "aws_lb_listener" "jenkins-listener-http" {
  provider          = aws.region-master
  load_balancer_arn = aws_lb.application-lb.arn # Tie listener to the load balancer
  port              = "80"                      # incomming requests from the internet
  protocol          = "HTTP"
  default_action {
    # type             = "forward"
    # target_group_arn = aws_lb_target_group.app-lb-tg.id
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" # 301 is a permaneent redirect
    }
  }
}

#Create new listener on tcp/443 HTTPS
resource "aws_lb_listener" "jenkins-listener-https" {
  provider          = aws.region-master
  load_balancer_arn = aws_lb.application-lb.arn
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.jenkins-lb-https.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app-lb-tg.arn # Target group attached to load balancer
  }
}

# Attach the EC2 isntance to the target group (one attachment per EC2)
resource "aws_lb_target_group_attachment" "jenkins-master-instance-attach" {
  provider         = aws.region-master
  target_group_arn = aws_lb_target_group.app-lb-tg.arn
  target_id        = aws_instance.jenkins-master-instance.id
  port             = var.application-port
}
