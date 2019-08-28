resource "aws_security_group" "base-security-group" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "base-security-group"
  description = "security group that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    # Should be changed to a white list of IPs
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "base-security-group"
  }
}

resource "aws_security_group" "allow-aurora" {
  vpc_id      = "${aws_vpc.main.id}"
  name        = "allow-aurora"
  description = "allow-aurora"
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = ["${aws_security_group.base-security-group.id}"] # allowing access from our example instance
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    self        = true
  }
  tags = {
    Name = "allow-aurora"
  }
}
