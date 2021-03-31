# ACM CONFIGURATION (aws certificate management)

# Certificate creation
#
# This ACM certificate resource allows requesting and management of 
# certificates from the Amazon Certificate Manager. This resource 
# does not deal with validation of a certificate but can provide 
# inputs for other resources implementing the validation. It does 
# not wait for a certificate to be issued. Use a 
# aws_acm_certificate_validation resource for this (see below)
#
# In short, this represents a certificate to map and validate 
# HTTPS (port 443) traffic from the "jenkins.<dns name>" address 
# to the load balancer.
resource "aws_acm_certificate" "jenkins-lb-https" {
  provider          = aws.region-master
  domain_name       = join(".", ["jenkins", data.aws_route53_zone.dns.name]) # the domain name that is validated with this certificate
  validation_method = "DNS"                                                  # All validation performed by this certificate will be DNS validation (not email or other)
  tags = {
    Name = "Jenkins-ACM"
  }
}

# Validates ACM issued certificate via Route53, using the CNAME records
# from aws_route53_record.cert_validation
#
# This resource represents a successful validation of an ACM certificate in 
# concert with other resources. Most commonly, this resource is used together 
# with aws_route53_record and aws_acm_certificate to request a DNS validated 
# certificate, deploy the required validation records and wait for validation 
# to complete.
resource "aws_acm_certificate_validation" "cert" {
  provider        = aws.region-master
  certificate_arn = aws_acm_certificate.jenkins-lb-https.arn # The ARN of the certificate that is being validated.

  for_each                = aws_route53_record.cert_validation
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn] # List of FQDNs that will be used to perform the validation.
}