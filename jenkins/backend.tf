terraform {
  required_version = ">=0.13.0"
  required_providers {
    aws = ">=3.0.0"
  }
  backend "s3" {
    region  = "us-east-1"
    profile = "default"

    # aws s3 cp s3://terraformbucket12348765/terraformstatefile .
    key    = "terraformstatefile"
    bucket = "terraformbucket12348765"
  }
}
