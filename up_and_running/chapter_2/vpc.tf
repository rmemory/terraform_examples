#
# VPC
# 
resource "aws_vpc" "vpc" {
  provider = aws.default-provider

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
    Name = "vpc"
  }
}

#
# Internet gateway
#

# Internet gateway for the VPC 
# All public subnets are connected to gateway via the routing table defined
# below.
resource "aws_internet_gateway" "igw" {
  provider = aws.default-provider
  vpc_id   = aws_vpc.vpc.id

  tags = {
    Name = "igw"
  }
}

#
# Subnets
#

# Get all available AZ's in VPC for region
data "aws_availability_zones" "azs" {
  provider = aws.default-provider
  state    = "available"
}

# Public subnet #1
resource "aws_subnet" "public-1" {
  provider                = aws.default-provider
  availability_zone       = element(data.aws_availability_zones.azs.names, 0)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public-subnet-1"
    Tier = "Public"
  }
}

# Public subnet #2
resource "aws_subnet" "public-2" {
  provider                = aws.default-provider
  availability_zone       = element(data.aws_availability_zones.azs.names, 1)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "true"

  tags = {
    Name = "public-subnet-2"
    Tier = "Public"
  }
}

# Private subnet #1
resource "aws_subnet" "private-1" {
  provider                = aws.default-provider
  availability_zone       = element(data.aws_availability_zones.azs.names, 2)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "private-subnet-1"
    Tier = "Private"
  }
}

# Private subnet #2
resource "aws_subnet" "private-2" {
  provider                = aws.default-provider
  availability_zone       = element(data.aws_availability_zones.azs.names, 3)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "private-subnet-2"
    Tier = "Private"
  }
}

#
# Route tables
#

# Public route table
resource "aws_route_table" "public-route-table" {
  provider = aws.default-provider
  vpc_id   = aws_vpc.vpc.id

  # All traffic from instances that is not addressed to 
  # an internal address inside the VPC (ie. 10.0.x.x) 
  # will be routed over the gateway to the internet gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  # We don't want updates to the gateway or peering connection
  # to update the route table
  lifecycle {
    ignore_changes = all // ignore changes to other entities, but will not ignore deletion
  }

  tags = {
    Name = "Public Route Table"
  }
  depends_on = [aws_vpc.vpc, aws_internet_gateway.igw]
}

# Overwrite default route table with our route table entries
# The default route table is used by all subnets not explicitly
# assigned to any other route table. By making the default route
# table tied to a route to the IGW, it means any subnet assigned
# to this route table (either explicitly or implied) will be a 
# "public subnet"
resource "aws_main_route_table_association" "route-association" {
  provider       = aws.default-provider
  vpc_id         = aws_vpc.vpc.id
  route_table_id = aws_route_table.public-route-table.id
  depends_on     = [aws_route_table.public-route-table]
}

# The following are examples of the association of subnets with
# non-default route tables.

#resource "aws_route_table_association" "public-1" {
#  subnet_id      = aws_subnet.public-1.id
#  route_table_id = aws_route_table.foo.id
#}
#resource "aws_route_table_association" "public-2" {
#  subnet_id      = aws_subnet.public-2.id
#  route_table_id = aws_route_table.bar.id
#}

#
# NAT
#

# elastic IP for NAT
resource "aws_eip" "nat-eip" {
  provider   = aws.default-provider
  vpc        = true
  depends_on = [aws_vpc.vpc]
}

resource "aws_nat_gateway" "nat-gw" {
  provider      = aws.default-provider
  allocation_id = aws_eip.nat-eip.id
  subnet_id     = aws_subnet.public-1.id
  depends_on    = [aws_eip.nat-eip, aws_subnet.public-1]
}

# Route table for instances on private subnets to access
# the internet via the NAT
resource "aws_route_table" "nat-route-table" {
  provider = aws.default-provider
  vpc_id   = aws_vpc.vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw.id
  }

  tags = {
    Name = "Nat Route Table"
  }
  depends_on = [aws_nat_gateway.nat-gw]
}

# route associations for private subnets
resource "aws_route_table_association" "private-1" {
  provider       = aws.default-provider
  subnet_id      = aws_subnet.private-1.id
  route_table_id = aws_route_table.nat-route-table.id
  depends_on     = [aws_subnet.private-1, aws_route_table.nat-route-table]
}
resource "aws_route_table_association" "private-2" {
  provider       = aws.default-provider
  subnet_id      = aws_subnet.private-2.id
  route_table_id = aws_route_table.nat-route-table.id
  depends_on     = [aws_subnet.private-2, aws_route_table.nat-route-table]
}

# 
# Security Groups
#
resource "aws_security_group" "dmz-sg" {
  provider    = aws.default-provider
  name        = "dmz-sg"
  description = "Allow ssh on TCP/22"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.external_ip]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
