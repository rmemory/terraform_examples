# Internet VPC
resource "aws_vpc" "main" {
  # 65536 IP addresses available (private)
  # from 10.0.0.0 to 10.0.255.255
  cidr_block = "10.0.0.0/16"

  #Other blocks that are available
  #172.16.0.0/12, from 172.16.0.0 to 172.31.255.255
  #192.168.0.0/16, from 192.168.0.0 to 192.168.255.255

  # default tenancy implies each instance can run on 
  # any hardware selected by AWS (non-tenancy is expensive)
  instance_tenancy = "default"

  # instances provide internal dns support
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"

  # Classic AWS is basically one big network where all AWS instances are launched
  enable_classiclink = "false"

  tags = {
    # This name will be visible in AWS Dashboard
    Name = "main"
  }
}

# Subnets
# 3 public and 3 private subnets
# All instances in VPC will be assigned to one of these subnets
# Any instance attached to a public subnet will be given a public IP
# The top level private IP address block is defined by VPC (10.0.x.x)
# Each subnet will have 255 IP addresses available to it
# All the public subnets are connected to an internet gateway

# 3 public subnets
resource "aws_subnet" "main-public-1" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.1.0/24"

  # This gives all instances on this subnet a public IP
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "main-public-1"
  }
}
resource "aws_subnet" "main-public-2" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.2.0/24"

  # This gives all instances on this subnet a public IP
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "main-public-2"
  }
}
resource "aws_subnet" "main-public-3" {
  vpc_id     = "${aws_vpc.main.id}"
  cidr_block = "10.0.3.0/24"

  # This gives all instances on this subnet a public IP
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1c"

  tags = {
    Name = "main-public-3"
  }
}

# 3 private subnets
resource "aws_subnet" "main-private-1" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "main-private-1"
  }
}
resource "aws_subnet" "main-private-2" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1b"

  tags = {
    Name = "main-private-2"
  }
}
resource "aws_subnet" "main-private-3" {
  vpc_id                  = "${aws_vpc.main.id}"
  cidr_block              = "10.0.6.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1c"

  tags = {
    Name = "main-private-3"
  }
}

# Internet GW
# All public subnets are connected to gateway
resource "aws_internet_gateway" "main-gw" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "main"
  }
}

# route tables
# This route table will be pushed to instances
resource "aws_route_table" "main-public" {
  vpc_id = "${aws_vpc.main.id}"

  # All traffic from instances that is not addressed to 
  # an internal address in the VPC (ie. 10.0.x.x) 
  # will be routed over the gateway to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main-gw.id}"
  }

  tags = {
    Name = "main-public-1"
  }
}

# route public subnets to gateway
# these associations are required to push the route table above
# to instances assigned to each subnet
resource "aws_route_table_association" "main-public-1-a" {
  subnet_id      = "${aws_subnet.main-public-1.id}"
  route_table_id = "${aws_route_table.main-public.id}"
}
resource "aws_route_table_association" "main-public-2-a" {
  subnet_id      = "${aws_subnet.main-public-2.id}"
  route_table_id = "${aws_route_table.main-public.id}"
}
resource "aws_route_table_association" "main-public-3-a" {
  subnet_id      = "${aws_subnet.main-public-3.id}"
  route_table_id = "${aws_route_table.main-public.id}"
}
