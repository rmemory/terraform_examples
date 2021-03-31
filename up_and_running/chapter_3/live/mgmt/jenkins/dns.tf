# aws_route53_zone represents a Route53 Hosted Zone.
#
# A hosted zone is a container for "Route53 records" which define the routing 
# rules for the base DNS address.
#
# This data resource will obtain an already existing Hosted Zone on Route53.
# It won't create it. Hence it uses the hardcoded var.dns.name value.
data "aws_route53_zone" "dns" {
  provider = aws.us-east-1
  name     = var.dns_name
}

#
# This resource points the route53 DNS name to the ALB DNS name
#
# jenkins.<var.dns_name> -> ALB DNS 
#
resource "aws_route53_record" "jenkins" {
  provider = aws.us-east-1
  zone_id  = data.aws_route53_zone.dns.zone_id
  name     = join(".", ["jenkins", data.aws_route53_zone.dns.name]) 
  type     = "A"                                                    

  # Addressing information for load balancer
  alias {
    name                   = aws_lb.application_lb.dns_name
    zone_id                = aws_lb.application_lb.zone_id
    evaluate_target_health = true
  }
}

## Everything below this point is issuing the certificate and validating
## that we own the domain.

# ACM CONFIGURATION (aws certificate management)
#
# Certificate creation for jenkins.<var.dns_name>
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
resource "aws_acm_certificate" "cert" {
  provider          = aws.us-east-1
  domain_name       = join(".", ["jenkins", data.aws_route53_zone.dns.name]) # the domain name that is validated with this certificate
  validation_method = "DNS"                                                  # All validation performed by this certificate will be DNS validation (not email or other). I think this also causes this resource to create the domain_validation_options (or the internal CNAME records validated by aws_route53_record.cert_validation)
  tags = {
    Name = "jenkins_acm"
  }
}

# This is where AWS verifies that we own and control all of the addresses
# in the hosted zone.
#
# The ACM manager in AWS uses CNAME records to validate that we own and control 
# the domain name listed in aws_acm_certificate.cert.domain_name.
#
resource "aws_route53_record" "cert_validation" {
  provider = aws.us-east-1

  # domain_validation_options represents the set of (list of) addresses (in the
  # form of DNS entries) to validate an incoming request on the application 
  # domain(www.foobar.com) is valid as per the certificate from ACM. 
  #
  # Think of them as the set of rules the ACM says is necessary to validate 
  # this hosted domain is owned by us.
  #  
  # These records are only used internally by the
  # aws_acm_certificate_validation resource to validate the domain name
  # with the certificate. 
  for_each = {
    for val in aws_acm_certificate.cert.domain_validation_options : val.domain_name => {
      name   = val.resource_record_name
      record = val.resource_record_value
      type   = val.resource_record_type
    }
  }
  name    = each.value.name     # For example, "438d429452836325795876703acbb02a.jenkins.cmcloudlab741.info."
  records = [each.value.record] # For example, ["_ab7f0ea865fade3a259907cd451c5a4b.wggjkglgrm.acm-validations.aws."]
  type    = each.value.type     # Should always be CNAME
  zone_id = data.aws_route53_zone.dns.zone_id
  ttl = 60
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
  provider        = aws.us-east-1
  certificate_arn = aws_acm_certificate.cert.arn # The ARN of the certificate that is being validated.

  for_each                = aws_route53_record.cert_validation
  validation_record_fqdns = [aws_route53_record.cert_validation[each.key].fqdn] # List of FQDNs that will be used to perform the validation.
}