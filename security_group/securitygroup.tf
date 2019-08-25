data "aws_ip_ranges" "us_east_ec2" {
  regions = [ "us-east-1" ]
  services = [ "ec2" ]
}

output "ec2_cidr_blocks" {
  value = "${data.aws_ip_ranges.us_east_ec2.cidr_blocks}"
}

resource "aws_security_group" "from_us_east" {
 name = "from_us_east"

  ingress {
    from_port = "443"
    to_port = "443"
    protocol = "tcp"
    cidr_blocks = [ "${data.aws_ip_ranges.us_east_ec2.cidr_blocks}" ]
  }
  tags = {
    #create_date - The publication time of the IP ranges (e.g. 2016-08-03-23-46-05).
    CreateDate = "${data.aws_ip_ranges.us_east_ec2.create_date}"
    #sync_token - The publication time of the IP ranges, in Unix epoch time format (e.g. 1470267965).
    SyncToken = "${data.aws_ip_ranges.us_east_ec2.sync_token}"
  }

}
