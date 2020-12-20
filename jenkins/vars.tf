variable "profile" {
  type    = string
  default = "default"
}

variable "region-master" {
  type    = string
  default = "us-east-1"
}

variable "region-worker" {
  type    = string
  default = "us-west-2"
}

variable "external_ip" {
  type    = string
  default = "0.0.0.0/0" # default is all IP addresses
}

variable "workers-count" {
  type    = number
  default = 1
}

variable "instance-type" {
  type    = string
  default = "t3.micro"
}

variable "application-port" {
  type    = number
  default = 8080
}

# $ aws route53 list-hosted-zones
# Navigate to Route53, select "HostedZone" , and create a new Hostted zone with format of cmcloudlab1234.info.com
# A public domain is required do that we can use a certificate and https (443)
# A route53 domain has a public host zone attached to it, which contains an alias pointing to the DNS name of the ALB
variable "dns-name" {
  type    = string
  default = "cmcloudlab741.info." #example cmcloudlab1234.info.
}
