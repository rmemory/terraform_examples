variable "instance_count" {
  default     = 3
  description = "Always have at least 3 instances in your Aurora cluster"
}

variable "enabled" {
  type        = "string"
  default     = true
  description = "Create DB resources?"
}

variable "db_identifier_prefix" {
  default     = "testdb"
  description = "Name for the DB"
}

# List of public subnets
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "1547765456n44a36-tf-state-random-bucket-name"
    key    = "stage/data-stores/aurora/terraform-tfstate"
    region = "us-east-1"
  }
}
data "aws_subnet_ids" "private" {
  provider = aws.us-east-1-provider
  vpc_id   = data.terraform.remote_state.vpc.outputs.vpc_id
  tags = {
    Tier = "Private"
  }
}

resource "aws_db_subnet_group" "aurora-subnet" {
  name        = "aurora-subnet"
  description = "Aurora subnet group"
  subnet_ids  = aws_subnet_ids.private.ids
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier              = var.db_cluster_identifier_prefix-var.envname
  engine                          = "aurora-postgresql"
  db_subnet_group_name            = aws_db_subnet_group.aurora-subnet.name
  database_name                   = "recovery_database"
  master_username                 = "recovery_admin"
  master_password                 = "${var.RDS_PASSWORD}"
  backup_retention_period         = 5
  skip_final_snapshot             = true
  preferred_backup_window         = "07:00-09:00"
  db_cluster_parameter_group_name = "default.aurora-postgresql10"
  vpc_security_group_ids          = aws_security_group.allow-aurora.id
}

resource "aws_rds_cluster_instance" "cluster_instance" {
  count                      = var.enabled ? var.instance_count : 0
  identifier                 = var.db_identifier_prefix-var.envname-count.index
  cluster_identifier         = aws_rds_cluster.cluster.id
  engine                     = "aurora-postgresql"
  engine_version             = 10.7
  instance_class             = "db.r5.large"
  publicly_accessible        = true
  db_subnet_group_name       = aws_db_subnet_group.aurora-subnet.name
  apply_immediately          = true
  auto_minor_version_upgrade = true
  db_parameter_group_name    = "default.aurora-postgresql10"
}
