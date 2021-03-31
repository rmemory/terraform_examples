output "address" {
  value       = aws_db_instance.mysql.address
  description = "Connect to the database at this endpoint"
}

output "port" {
  value       = aws_db_instance.mysql.port
  description = "The port the database is listening on"
}

resource "aws_db_instance" "mysql" {
  provider          = aws.us-east-1-provider
  identifier_prefix = "myexample"
  engine            = "mysql"
  engine_version    = "5.6"
  allocated_storage = 10
  max_allocated_storage = 20
  allow_major_version_upgrade = true
  auto_minor_version_upgrade = true
  multi_az = true
  db_subnet_group_name = aws_db_subnet_group.default.name
  parameter_group_name = aws_db_parameter_group.default.name
  instance_class    = "db.t2_micro"
  name              = "example_database"
  username          = "admin"

  password = data.aws_secretsmanager_secret_version.db_password.secret_string
}

resource "aws_db_parameter_group" "default" {
  name   = "rds-pg"
  family = "mysql5.6"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}

# 
# Get list of public subnets. The ASG will launch the instances onto these
# subnets. See aws_autoscaling_group.asg.vpc_zone_identifier below.
#
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "1547765456n44a36-tf-state-random-bucket-name"
    key    = "stage/data-stores/mysql/terraform-tfstate"
    region = "us-east-1"
  }
}
data "aws_subnet_ids" "private" {
  provider = aws.us-east-1-provider
  vpc_id   = data.terraform_remote_state.vpc.outputs.vpc_id
  tags = {
    Tier = "Private"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = aws_subnet_ids.private.ids

  tags = {
    Name = "My DB subnet group"
  }
}

data "aws_secretsmanager_secret_version" "db_password" {
  provider  = aws.us-east-1-provider
  secret_id = "arn:aws:secretsmanager:us-east-1:378407054436:secret:MYSQL_password-B7d56d"
}

# Note the extra leading space in the following command so that the command
# doesn't go into the shell's command history
#
#  export TF_VAR_db_password='the_password' 
# variable "db_password" {
#     description = "The password for the database"
#     type = string
# }