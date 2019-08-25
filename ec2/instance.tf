resource "aws_key_pair" "the-key" {
  key_name = "my_key"
  public_key = "${file("${var.PATH_TO_PUBLIC_KEY}")}"
}

resource "aws_instance" "example" {
  ami = "${lookup(var.AMIS, var.AWS_REGION)}"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.the-key.key_name}"

  // Copy a script to instance
  provisioner "file" {
    source = "script.sh"
    destination = "/tmp/script.sh"
  }
  provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/script.sh",
        "sudo /tmp/script.sh"
      ]
  }
  provisioner "local-exec" {
    command = "echo ${aws_instance.example.public_ip} >> private_ips.txt"
  }
  connection {
    // When spinning up instances on AWS, ec2-user is the default user
    host = "${self.public_ip}"
    user = "${var.INSTANCE_USERNAME}"
    private_key = "${file("${var.PATH_TO_PRIVATE_KEY}")}"
  }
}

output "ip" {
  value = "${aws_instance.example.public_ip}"
}