# Login using ssh 54.237.177.231 -l ubuntu -i mykey

resource "aws_instance" "ec2" {
  ami           = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t2.micro"

  # the VPC subnet
  subnet_id = "${aws_subnet.main-public-1.id}"

  # the security group
  vpc_security_group_ids = ["${aws_security_group.base-security-group.id}"]

  # the public SSH key
  key_name = "${aws_key_pair.mykeypair.key_name}"

  root_block_device {
    volume_size           = 16
    volume_type           = "gp2"
    delete_on_termination = true
  }

  // Copy a script to instance
  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "sudo /tmp/script.sh"
    ]
  }
  connection {
    // When spinning up instances on AWS, ec2-user is the default user
    host        = "${self.public_ip}"
    user        = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }
}

resource "aws_ebs_volume" "ebs-volume-1" {
  availability_zone = "us-east-1a"
  size              = 20
  type              = "gp2"
  tags = {
    Name = "extra volume data"
  }
}

resource "aws_volume_attachment" "ebs-volume-1-attachment" {
  device_name = "/dev/xvdh"
  volume_id   = "${aws_ebs_volume.ebs-volume-1.id}"
  instance_id = "${aws_instance.ec2.id}"
}

output "ip" {
  value = "${aws_instance.ec2.public_ip}"
}
