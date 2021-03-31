
#
# Create VPC in us-west-2
#
resource "aws_vpc" "worker" {
  provider = aws.us-west-2

  # Addresses used within the VPC
  # 65536 IP addresses available (private)
  # from 192.168.0.0 to 192.168.255.255
  cidr_block = "192.168.0.0/16"

  #Other blocks that are available to VPCs
  #172.16.0.0/12, from 172.16.0.0 to 172.31.255.255
  #10.0.0.0/16, from 10.10.0.0 to 10.0.255.255

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

  # Classic AWS is basically one big network where all AWS instances are launched
  enable_classiclink = "false"

  tags = {
    Name = "jenkins-worker-vpc"
  }
}

# Internet gateway for the VPC at region-worker
# All public subnets are connected to gateway via the routing table defined
# below.
resource "aws_internet_gateway" "worker_igw" {
  provider = aws.us-west-2
  vpc_id   = aws_vpc.worker.id

  tags = {
    Name = "worker_igw"
  }
}

# Create public subnet #1 in us-west-2
resource "aws_subnet" "worker_subnet_public_1" {
  provider = aws.us-west-2
  # availability_zone not specified
  vpc_id     = aws_vpc.worker.id
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "worker_subnet_public_1"
  }
}

# Private subnet #1 in us-west-2
resource "aws_subnet" "worker_subnet_private_1" {
  provider = aws.us-west-2
  # availability_zone not specified
  vpc_id                  = aws_vpc.worker.id
  cidr_block              = "192.168.2.0/24"
  map_public_ip_on_launch = "false"

  tags = {
    Name = "worker_subnet_private_1"
  }
}

#Accept VPC peering request in us-west-2 from us-east-1
resource "aws_vpc_peering_connection_accepter" "useast1_uswest2" {
  provider                  = aws.us-west-2
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  auto_accept               = true # requires both VPC to be in same account
}

#Create route table in us-west-2
resource "aws_route_table" "worker_public_route_tbl" {
  provider = aws.us-west-2
  vpc_id   = aws_vpc.worker.id

  # All traffic from within the VPC addresses to external addresses
  # not from the peer VPC will be routed through the igw
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.worker_igw.id
  }

  # This allows instances from this VPC to talk to instances
  # inside the master VPC
  route {
    cidr_block                = "10.0.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1_uswest2.id
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "worker_public_route_tbl"
  }
}

#Overwrite default route table of VPC(Worker) with our route table entries
resource "aws_main_route_table_association" "worker_route_association" {
  provider       = aws.us-west-2
  vpc_id         = aws_vpc.worker.id
  route_table_id = aws_route_table.worker_public_route_tbl.id
}