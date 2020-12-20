# aws_route53_zone represents a Route53 Hosted Zone. A hosted zone is a 
# container for "Route53 records" which define the routing rules for
# the hosted zone.
#
# Domain names and hosted zone names are synonymous
#
# This date resource will obtain an already existing Hosted Zone on Route53.
# It won't create it. Hence it uses the hardcoded var.dns.name value.
data "aws_route53_zone" "dns" {
  provider = aws.region-master
  name     = var.dns-name
}

# Route53 records are route defintions for DNS. In other words, where do
# requests on a domain name (www.foobar.com) get routed to are defined using
# records.
#
# Stated differently, after you create a hosted zone for your domain, such as f
# oobar.com, you create records to tell the Domain Name System (DNS) how you want 
# traffic to be routed for that domain.
#
# This record is an "alias record" (type = "A") and it routes traffic from the 
# domain name to the ALB from Route53.
#
# This record is also known as a "simple routing" record.
#
resource "aws_route53_record" "jenkins" {
  provider = aws.region-master
  zone_id  = data.aws_route53_zone.dns.zone_id
  name     = join(".", ["jenkins", data.aws_route53_zone.dns.name]) # route all traffic from this domain to the load balancer
  type     = "A"                                                    # Alias record

  # Addressing information for load balancer                                                    # alias record
  alias {
    name                   = aws_lb.application-lb.dns_name
    zone_id                = aws_lb.application-lb.zone_id
    evaluate_target_health = true
  }
}

# These records are the CNAME records for the domain. These records are only
# used internally with the ACM (ie. certificate manager) to validate the 
# the domain which is required to use HTTPS (port 443).
#
# When these exist, they tell AWS that requests on the domain (www.foobar.com)
# must be validated by the ACM certificate.
#
# The ACM manager in AWS uses CNAME records to validate we own and control 
# the domain name listed in aws_acm_certificate.jenkins-lb-https.domain_name
#
resource "aws_route53_record" "cert_validation" {
  provider = aws.region-master
  zone_id  = data.aws_route53_zone.dns.zone_id

  # domain_validation_options represents the set of (list of) addresses (in the
  # form of DNS entries) to validate an incoming request on the application domain
  # (www.foobar.com) is valid as per the certificate from ACM. 
  #
  # Think of them as the set of rules the ACM decides is necessary to validate this
  # domain.
  #  
  # These records are only used internally by the
  # aws_acm_certificate_validation resource to validate the domain name
  # with the certifcate. That resource accesses each one like this:
  # 
  # aws_route53_record.cert_validation[the domain_name string].fqdn
  for_each = {
    for val in aws_acm_certificate.jenkins-lb-https.domain_validation_options : val.domain_name => {
      name   = val.resource_record_name
      record = val.resource_record_value
      type   = val.resource_record_type
    }
  }
  name    = each.value.name     # For example, "438d429452836325795876703acbb02a.jenkins.cmcloudlab741.info."
  records = [each.value.record] # For example, ["_ab7f0ea865fade3a259907cd451c5a4b.wggjkglgrm.acm-validations.aws."]
  type    = each.value.type     # Should always be CNAME

  # For what is't worth, records of type CNAME are aliasing one domain to another 
  # domain. Never to an IP address

  ttl = 60
}