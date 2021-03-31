provider "aws" {
  profile = "default"
  region  = "us-east-1"

  alias = "us-east-1"
}

terraform {
  required_providers {
    aws = ">=3.0.0"
  }

  required_version = ">=0.13.0"

  # For the backend, use an HCL file called backend.hcl ...
  # bucket         = "some-unique-bucket-name"
  # region         = "us-east-1"
  # profile        = "default"
  # dynamodb_table = "tf_state_locks"
  # encrypt        = true

  # Uncomment the following
  # backend "s3" {
  #   key = "paste path inside bucket to terrafrom state file"
  # }

  # Initialize terraform like this ...
  # terraform init -backend-config=<path to backend.hcl>
}