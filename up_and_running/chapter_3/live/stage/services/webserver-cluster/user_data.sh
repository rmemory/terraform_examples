#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
cat > /var/www/html/index.html <<EOF
<h1>Hello world</h1>
<p>DB Address: ${db_address}</p>
<p>DB Port: ${db_port}</p>
EOF
sudo systemctl start httpd
sudo systemctl enable httpd
