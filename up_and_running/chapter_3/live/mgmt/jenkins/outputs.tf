# terraform state list

# terraform console
# > aws_vpc.vpc_useast

# terraform graph > tf.dot
# sudo apt install graphviz
# cat tf.dot | dot -Tpng -otf.png
# terraform 

output "ami_id_us_east_1" {
  value = data.aws_ssm_parameter.primary_linux_ami.value
}

output "ami_id_us_west_2" {
  value = data.aws_ssm_parameter.worker_linux_ami.value
}

output "jenkins_primary_public_ip" {
  value = aws_instance.jenkins_primary.public_ip
}

output "jenkins_primary_private_ip" {
  value = aws_instance.jenkins_primary.private_ip
}

output "jenkins_worker_public_ips" {
  value = {
    for instance in aws_instance.jenkins_worker :
    instance.id => instance.public_ip
  }
}

output "jenkins_worker_private_ips" {
  value = {
    for instance in aws_instance.jenkins_worker :
    instance.id => instance.private_ip
  }
}

output "alb_dns" {
  value = aws_lb.application_lb.dns_name
}

output "jenkins_url" {
  value = aws_route53_record.jenkins.fqdn
}