Generic script
==============
#!/bin/bash
yum install httpd php php-mysql -y
cd /var/www/html
wget https://wordpress.org/wordpress-5.1.1.tar.gz
tar -xzf wordpress-5.1.1.tar.gz
cp -r wordpress/* /var/www/html/
rm -rf wordpress
rm -rf wordpress-5.1.1.tar.gz
chmod -R 755 wp-content
chown -R apache:apache wp-content
service httpd start
chkconfig httpd on

AWS script
==========
#!/bin/bash  
yum update -y  
yum install amazon-linux-extras httpd -y  
amazon-linux-extras install php7.4 -y
cd /var/www/html  
wget https://wordpress.org/latest.tar.gz  
tar xzf latest.tar.gz  
cp -r wordpress/* /var/www/html/  
rm -rf wordpress latest.tar.gz  
chmod -R 755 wp-content  
chown -R apache:apache wp-content  
service httpd start  
chkconfig httpd on

acloudguru.c97cxx05ahhv.us-east-1.rds.amazonaws.com