#
# Create VPC in us-east-1
# 
resource "aws_vpc" "master" {
  provider = aws.region-master

  # Addresses used within the VPC
  # 65536 IP addresses are available (private)
  # from 10.0.0.0 to 10.0.255.255
  cidr_block = "10.0.0.0/16"

  #Other blocks that are available to VPCs
  #172.16.0.0/12, from 172.16.0.0 to 172.31.255.255
  #192.168.0.0/16, from 192.168.0.0 to 192.168.255.255

  # default tenancy implies each instance can run on 
  # any hardware selected by AWS (non-tenancy is expensive)
  instance_tenancy = "default"

  # If this attribute is false, the Amazon Route 53 Resolver server that 
  # resolves public DNS hostnames to IP addresses is not enabled.
  # If this attribute is true, queries to the Amazon provided DNS server 
  # at the 169.254.169.253 IP address, or the reserved IP address at the 
  # base of the VPC IPv4 network range plus two will succeed. 
  enable_dns_support = "true"

  # Indicates whether instances with public IP addresses get corresponding 
  # public DNS hostnames.
  # If this attribute is true, instances in the VPC get public DNS hostnames, 
  # but only if the enableDnsSupport attribute is also set to true.
  enable_dns_hostnames = "true"

  # Classic AWS is basically one big network where all AWS instances are 
  # launched
  enable_classiclink = "false"

  tags = {
    Name = "master-vpc-jenkins"
  }
}

# Internet gateway for the VPC at region-master
# All public subnets are connected to gateway via the routing table defined
# below.
resource "aws_internet_gateway" "igw-master" {
  provider = aws.region-master
  vpc_id   = aws_vpc.master.id

  tags = {
    Name = "master-igw"
  }
}

# Get all available AZ's in VPC for master region
data "aws_availability_zones" "master-azs" {
  provider = aws.region-master
  state    = "available"
}

# Create subnet #1 in us-east-1
resource "aws_subnet" "master-subnet-public-1" {
  provider                = aws.region-master
  availability_zone       = element(data.aws_availability_zones.master-azs.names, 0)
  vpc_id                  = aws_vpc.master.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "master-subnet-public-1"
  }
}

# Create subnet #2 in us-east-1
resource "aws_subnet" "master-subnet-public-2" {
  provider                = aws.region-master
  availability_zone       = element(data.aws_availability_zones.master-azs.names, 1)
  vpc_id                  = aws_vpc.master.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "master-subnet-public-2"
  }
}

# Private subnet #1 in us-east-1
resource "aws_subnet" "master-subnet-private-1" {
  provider                = aws.region-master
  availability_zone       = element(data.aws_availability_zones.master-azs.names, 2)
  vpc_id                  = aws_vpc.master.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "master-subnet-private-1"
  }
}

# VPC peering request from us-east-1 to us-west-1
resource "aws_vpc_peering_connection" "useast1-uswest2" {
  provider    = aws.region-master
  peer_vpc_id = aws_vpc.worker.id
  vpc_id      = aws_vpc.master.id
  peer_region = var.region-worker
}

#Create route table in us-east-1
resource "aws_route_table" "master-internet-route-table" {
  provider = aws.region-master
  vpc_id   = aws_vpc.master.id

  # All traffic from instances that is not addressed to 
  # an internal address inside the VPC (ie. 10.0.x.x) 
  # will be routed over the gateway to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw-master.id
  }

  # All traffic from instances addressed to a 192.168.1.x 
  # address will be routed to the peer vpc
  route {
    cidr_block                = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }

  # We don't want updates to the gateway or peering connection
  # to update the route table
  lifecycle {
    ignore_changes = all // ignore changes to other entities, but will not ignore deletion
  }
  tags = {
    Name = "Master-Region-RouteTable"
  }
}

#Overwrite default route table of VPC(Master) with our route table entries
resource "aws_main_route_table_association" "master-route-association" {
  provider       = aws.region-master
  vpc_id         = aws_vpc.master.id
  route_table_id = aws_route_table.master-internet-route-table.id
}

# If we wanted to create a custom route association for a particular
# subnet we could use one of these.

#resource "aws_route_table_association" "main-public-1-a" {
#  subnet_id      = aws_subnet.main-public-1.id
#  route_table_id = aws_route_table.main-public.id
#}
#resource "aws_route_table_association" "main-public-2-a" {
#  subnet_id      = aws_subnet.main-public-2.id
#  route_table_id = aws_route_table.main-public.id
#}
#resource "aws_route_table_association" "main-public-3-a" {
#  subnet_id      = aws_subnet.main-public-3.id
#  route_table_id = aws_route_table.main-public.id
#}

