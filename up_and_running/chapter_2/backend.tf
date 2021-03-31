terraform {
  required_version = ">=0.13.0"
  
  required_providers {
    aws = ">=3.0.0"
  }

  #  To store terraform state in a bucket, uncomment the following
  #  backend "s3" {
  #    region  = "us-east-1"
  #    profile = "default"
  #    key    = "terraformstatefile"
  #    bucket = "terraformbucket12348765"
  #  }
}
