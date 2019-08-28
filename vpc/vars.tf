variable "AWS_REGION" {
  default = "us-east-1"
}
variable "PATH_TO_PRIVATE_KEY" {
  default = "mykey"
}
variable "PATH_TO_PUBLIC_KEY" {
  default = "mykey.pub"
}

variable "ROLE_ARN_ID" {
  type        = "string"
  description = "ARN value for IAM power user role"
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

variable "INSTANCE_USERNAME" {
  type        = "string"
  default     = "ubuntu"
  description = "Username to use in instance"
}

variable "RDS_PASSWORD" {
  type = "string"
}

variable "instance_count" {
    default = 3
    description = "Always have at least 3 instances in your Aurora cluster"
}

variable "enabled" {
  type        = "string"
  default     = true
  description = "Create DB resources?"
}

variable "db_identifier_prefix" {
  default = "testdb"
  description = "Name for your DB"
}

variable "db_cluster_identifier_prefix" {
  default = "testcluster"
  description = "Name for your DB cluster"
}

variable "envname" {
  type        = "string"
  default = "test"
  description = "Environment name (eg,test, stage or prod)"
}