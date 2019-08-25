variable "ROLE_ARN_ID" {
  type = "string"
  description = "ARN value for IAM power user role"
}

variable "AWS_REGION" {
  type = "string"
  default = "us-east-1"
}

variable "AMIS" {
  type = "map"
  // see https://cloud-images.ubuntu.com/locator/
  default = {
    us-east-1 = "ami-00290d66f0da25f73"
	us-east-2 = "ami-0b8b176ef4535c8e4"
	eu-west-1 = "ami-01787df05261973d3"
  }
}