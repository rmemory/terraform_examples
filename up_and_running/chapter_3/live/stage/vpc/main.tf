locals {
  main_vpc_cidr_block                = "10.0.0.0/16"
  main_public_subnet_1_cidr_block    = "10.0.1.0/24"
  main_public_subnet_2_cidr_block    = "10.0.2.0/24"
  main_private_subnet_1_cidr_block   = "10.0.3.0/24"
  main_private_subnet_2_cidr_block   = "10.0.4.0/24"
}

module "stage_vpc" {
  source      = "../../../modules/aws/vpc"
  #source       = "git::git@github.com:rmemory/terraform_modules.git//aws/vpc?ref=v0.0.4"

  vpc_name                    = "stage"
  vpc_cidr_block              = local.main_vpc_cidr_block
  public_subnet_1_cidr_block  = local.main_public_subnet_1_cidr_block
  public_subnet_2_cidr_block  = local.main_public_subnet_2_cidr_block
  private_subnet_1_cidr_block = local.main_private_subnet_1_cidr_block
  private_subnet_2_cidr_block = local.main_private_subnet_2_cidr_block

  providers = {
    aws = aws.us-east-1
  }
}

output vpc_id {
  value       = module.stage_vpc.vpc_id
  description = "The vpc ID"
}