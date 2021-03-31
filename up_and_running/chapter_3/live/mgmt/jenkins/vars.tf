# $ aws route53 list-hosted-zones
# Navigate to Route53, select "HostedZone", and create a new Hosted zone with 
# format of cmcloudlab1234.info.com
# A public domain is required do that we can use a certificate and https (443)
# A route53 domain has a public host zone attached to it, which contains an alias pointing to the DNS name of the ALB
variable "dns_name" {
  type    = string
  default = "cmcloudlab879.info." #example cmcloudlab1234.info.
}

variable "profile" {
  type    = string
  default = "default"
}

variable "primary_region" {
  type    = string
  default = "us-east-1"
}

variable "worker_region" {
  type    = string
  default = "us-west-2"
}

variable "external_ip" {
  type    = string
  default = "0.0.0.0/0" # default is all IP addresses
}

variable "workers_count" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "application_port" {
  type    = number
  default = 8080
}
