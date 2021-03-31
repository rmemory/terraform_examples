locals {
  cluster_name = "stage"
  vpc_bucket_tfstate = "1547765456n44a36-tf-state-random-bucket-name"
  vpc_bucket_tfstate_key = "stage/vpc/terraform-tfstate"
  vpc_region = "us-east-1"

  db_bucket_tfstate = "1547765456n44a36-tf-state-random-bucket-name"
  db_bucket_tfstate_key = "stage/data-stores/mysql/terraform-tfstate"
  db_region = "us-east-1"

  application_port = 80
  server_port = 80
  instance_type = "t3.micro"
  external_ips = ["0.0.0.0/0"]

  min_size = 2
  max_size = 5
  default_desired_capacity = 3
}

# 
# Get list of public subnets. The ASG will launch the instances onto these
# subnets.
#
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = local.vpc_bucket_tfstate
    key    = local.vpc_bucket_tfstate_key
    region = local.vpc_region
  }
}

data "aws_subnet_ids" "public" {
  provider = aws.us-east-1
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id
  tags = {
    Tier = "Public"
  }
}

resource "aws_security_group" "alb-sg" {
  provider = aws.us-east-1
  name        = "${local.cluster_name}-alb-sg"
  description = "Allow HTTP on TCP/application port"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress {
    description = "Allow application port access to load balancer from any IP"
    from_port   = local.application_port
    to_port     = local.application_port
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

module "alb" {
  source = "../../../../modules/aws/alb"
  #source = "git::git@github.com:rmemory/terraform_modules.git//aws/alb?ref=v0.0.4"
  name = local.cluster_name
  subnet_ids = data.aws_subnet_ids.public.ids
  server_port = local.server_port
  application_port = local.application_port
  security_group_ids = [aws_security_group.alb-sg.id]
  vpc_id = data.terraform_remote_state.vpc.outputs.vpc_id

  providers = {
      aws = aws.us-east-1
  }
}

#
# Get the parameters for the database (assumes the DB has been setup)
#
# data "terraform_remote_state" "db" {
#   backend = "s3"

#   config = {
#     bucket = local.db_bucket_tfstate
#     key = local.db_bucket_tfstate_key
#     region = local.db_region
#   }
# }

resource "aws_security_group" "dmz-sg" {
  provider = aws.us-east-1
  name        = "${local.cluster_name}-dmz-sg"
  description = "Allow ssh on TCP/22"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress {
    description = "Allow 22 from our public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.external_ips
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "asg" {
  source = "../../../../modules/aws/asg"
  #source = "git::git@github.com:rmemory/terraform_modules.git//aws/asg?ref=v0.0.4"
  name = local.cluster_name
  instance_type = local.instance_type
  server_port = local.server_port
  application_port = local.application_port
  alb_target_group_arn = module.alb.alb_target_group_arn
  subnet_ids = data.aws_subnet_ids.public.ids
  security_group_ids = [aws_security_group.dmz-sg.id, aws_security_group.web-sg.id]
  min_size = local.min_size
  max_size = local.max_size
  default_desired_capacity = local.default_desired_capacity
  enable_scheduled_autoscaling = false
  custom_tags = {
    Owner = "Richard Memory"
    DeployedBy = "Terraform"
  }

  providers = {
    aws = aws.us-east-1
  }
}

# Attach ALB to ASG
resource "aws_autoscaling_attachment" "asg_attachment" {
  provider = aws.us-east-1
  autoscaling_group_name = module.asg.asg_id
  alb_target_group_arn   = module.alb.alb_target_group_arn
}

output alb_dns_name {
  value       = module.alb.alb_dns_name
  description = "The domain name of the load balancer"
}

resource "aws_security_group" "web-sg" {
  provider = aws.us-east-1
  name        = "${local.cluster_name}-web-sg"
  description = "Allow HTTP on TCP/server port from load balancer"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  ingress {
    description     = "Allow application port access only from load balancer"
    from_port       = local.server_port
    to_port         = local.server_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb-sg.id]
  }
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
