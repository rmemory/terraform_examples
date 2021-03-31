variable "profile" {
  type    = string
  default = "default"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "external_ip" {
  type    = string
  default = "0.0.0.0/0" # default all IP addresses
}

variable "instance-type" {
  type    = string
  default = "t3.micro"
}

variable "server_port" {
  type    = number
  default = 80
}

variable "application_port" {
  type    = number
  default = 80
}
