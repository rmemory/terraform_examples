provider "aws" {
  profile = "default"
  region  = "us-east-1"

  #  assume_role {
  #    role_arn = "arn:aws:iam::${var.ROLE_ARN_ID}:role/cp-aws-sandbox-power-user-role"
  # You'll want to replace the arn with your own account arn with the proper permissions.
  # i.e. "arn:aws:iam::<your account number here>:role/cp-aws-sandbox-power-user-role"
  # }

  alias = "us-east-1"
}

terraform {
  required_providers {
    aws = ">=3.0.0"
  }

  required_version = ">=0.13.0"

  backend "s3" {
    key = "stage/vpc/terraform-tfstate"
  }
}