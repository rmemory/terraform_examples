# This security group is attached to the load balancer in the master VPC. It 
# allows incomming traffic on port 80 and port 443 from any address, and it 
# allows all outbound traffic from any resource attached to this SG
resource "aws_security_group" "lb-sg" {
  provider    = aws.region-master
  name        = "lb-sg"
  description = "Allow 443 and http traffic"
  vpc_id      = aws_vpc.master.id

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

# Create SG in us-east-1 for allowing TCP/8080 from * and TCP/22 from your IP 
# The load balancer will route incomming traffic to the following security group
# Jenkins runs on port 8080
resource "aws_security_group" "master-sg" {
  provider    = aws.region-master
  name        = "master-sg"
  description = "Allow TCP/application port (from alb) & TCP/22"
  vpc_id      = aws_vpc.master.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description     = "Allow traffic from LB on application port"
    from_port       = var.application-port
    to_port         = var.application-port
    protocol        = "tcp"
    security_groups = [aws_security_group.lb-sg.id]
  }
  ingress {
    description = "Allow all incomming traffic from us-west-2, worker-subnet-public-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.1.0/24"] #can't use subnet id here because of cicular definition
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create SG for allowing TCP/22 from your IP in us-west-2
resource "aws_security_group" "worker-sg" {
  provider = aws.region-worker

  name        = "worker-sg"
  description = "Allow TCP/22 and traffic from master"
  vpc_id      = aws_vpc.worker.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  ingress {
    description = "Allow traffic from master-subnet-public-1"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}