resource "aws_db_subnet_group" "aurora-subnet" {
  name        = "aurora-subnet"
  description = "RDS subnet group"
  subnet_ids  = ["${aws_subnet.main-private-1.id}", "${aws_subnet.main-private-2.id}"]
}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier      = "${var.db_cluster_identifier_prefix}-${var.envname}"
  engine                  = "aurora-postgresql"
  availability_zones      = ["${aws_subnet.main-private-1.availability_zone}"]
  db_subnet_group_name    = "${aws_db_subnet_group.aurora-subnet.name}"
  database_name           = "recovery_database"
  master_username         = "recovery_admin"
  master_password         = "${var.RDS_PASSWORD}"
  backup_retention_period = 5
  skip_final_snapshot = true
  preferred_backup_window = "07:00-09:00"
  db_cluster_parameter_group_name = "default.aurora-postgresql10"
  vpc_security_group_ids = ["${aws_security_group.allow-aurora.id}"]
}

resource "aws_rds_cluster_instance" "cluster_instance" {
  count                        = var.enabled ? var.instance_count : 0
  identifier                   = "${var.db_identifier_prefix}-${var.envname}-${count.index}"
  cluster_identifier           = aws_rds_cluster.cluster.id
  engine                       = "aurora-postgresql"
  engine_version               = 10.7
  instance_class               = "db.r5.large" 
  publicly_accessible          = true
  db_subnet_group_name         = "${aws_db_subnet_group.aurora-subnet.name}"
  apply_immediately            = true
  auto_minor_version_upgrade   = true
  db_parameter_group_name         = "default.aurora-postgresql10"
} 
