# https://aws.amazon.com/blogs/compute/query-for-the-latest-amazon-linux-ami-ids-using-aws-systems-manager-parameter-store/
# Get Linux AMI ID using SSM Parameter endpoint in us-east-1
# aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn*" --query 'sort_by(Images, &CreationDate)[].Name'
# aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --region us-east-1 
# Data sources are called first before provisioning
data "aws_ssm_parameter" "primary_linux_ami" {
  provider = aws.us-east-1
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

#Get Linux AMI ID using SSM Parameter endpoint in us-west-2
data "aws_ssm_parameter" "worker_linux_ami" {
  provider = aws.us-west-2
  name     = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Create the private/public key pair prior to creation of EC2
# AWS requires keys that are RSA 1048 bit keys, compatible with version 2 protocol of openssh
# $ ssh-keygen -t rsa
# ls ~/.ssh/id_rsa
# ls ~/.ssh/id_rsa.pub

#Please note that this code expects SSH key pair to exist in default dir under 
#users home directory, otherwise it will fail

# Keys are regional

#Create key-pair for logging into EC2 in us-east-1
resource "aws_key_pair" "primary_key" {
  provider   = aws.us-east-1
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub") 
}

#Create key-pair for logging into EC2 in us-west-2
resource "aws_key_pair" "worker_key" {
  provider   = aws.us-west-2
  key_name   = "jenkins"
  public_key = file("~/.ssh/id_rsa.pub")
}

#Create and bootstrap EC2 in us-east-1
resource "aws_instance" "jenkins_primary" {
  provider                    = aws.us-east-1
  ami                         = data.aws_ssm_parameter.primary_linux_ami.value # AMI is software configuration
  instance_type               = var.instance_type                     # instance type is hardware
  key_name                    = aws_key_pair.primary_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.primary_sg.id]
  subnet_id                   = aws_subnet.primary_subnet_public_1.id

  # Local provisioner. The command will wait until the ec2 instance becomes ok.
  # Once ok, ansible-playbook will use ssh to run the command on it.
  # Note that self.id and self.tags.name will return those pieces of information
  # about the EC2 instance.
  #   provisioner "local-exec" {
  #     command = <<EOF
  # aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.master_region} --instance-ids ${self.id}
  # ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins_primary_example.yml
  # EOF
  #   }
  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.primary_region} --instance-ids ${self.id} \
&& ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/install_jenkins.yaml
EOF
  }

  tags = {
    Name = "jenkins_primary_instance"
  }

  depends_on = [aws_main_route_table_association.primary_route_association] # this dependency is so this instance can talk to others
}

#Create EC2 in us-west-2
resource "aws_instance" "jenkins_worker" {
  provider                    = aws.us-west-2
  count                       = var.workers_count
  ami                         = data.aws_ssm_parameter.worker_linux_ami.value
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.worker_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.worker_sg.id]
  subnet_id                   = aws_subnet.worker_subnet_public_1.id


  # If a provisioner fails, it will be recreated the next time terraform is run
  #   provisioner "local-exec" {
  #     command = <<EOF
  # aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.region-worker} --instance-ids ${self.id}
  # ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name}' ansible_templates/jenkins_worker_example.yml
  # EOF
  #   }

  provisioner "local-exec" {
    command = <<EOF
aws --profile ${var.profile} ec2 wait instance-status-ok --region ${var.worker_region} --instance-ids ${self.id} \
&& ansible-playbook --extra-vars 'passed_in_hosts=tag_Name_${self.tags.Name} primary_ip=${self.tags.Primary_Private_IP}' ansible_templates/install_worker.yaml
EOF
  }

  # Deregisters worker from Jenkins running on primary EC2 when worker EC2 is deleted
  provisioner "remote-exec" {
    when = destroy
    inline = [
      "java -jar /home/ec2-user/jenkins-cli.jar -auth @/home/ec2-user/jenkins_auth -s http://${self.tags.Primary_Private_IP}:8080 -auth @/home/ec2-user/jenkins_auth delete-node ${self.private_ip}"
    ]
    connection { #These credentials are to log into the worker instance from the terraform host
      type        = "ssh"
      user        = "ec2-user"
      private_key = file("~/.ssh/id_rsa")
      host        = self.public_ip
    }
  }

  tags = {
    Name              = join("_", ["jenkins_worker_instance", count.index + 1])
    Primary_Private_IP = aws_instance.jenkins_primary.private_ip # private IP is used because that is how security groups between primary and worker are setup
  }

  # Only spin up instances after VPC and route table is established. Also, we 
  # want the jenkins primary instance to be started first
  depends_on = [aws_main_route_table_association.worker_route_association, aws_instance.jenkins_primary]
}
