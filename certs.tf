locals {
  
  domain = "${var.deployment}.${var.site_settings.route53_domain}"
  sans = concat(
    [local.domain],
    var.site_settings.top_level_domain == "" || var.deployment != "prod" ? [] : [var.site_settings.top_level_domain],
    var.site_settings.additional_domains == null ? tolist([]) : tolist(var.site_settings.additional_domains)
  )

}

resource "aws_acm_certificate" "cert" {
  domain_name               = local.domain
  subject_alternative_names = local.sans
  validation_method         = "DNS"
}

# Cert validation entries for anything with a route53 address
resource "aws_route53_record" "site_val_record" {
  provider = aws.dns

  for_each = {
    # for dvo in length(aws_acm_certificate.fqdn) > 0 ? aws_acm_certificate.fqdn[0].domain_validation_options : toset([]) : dvo.domain_name => {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } if length(regexall(var.route53_tld, dvo.domain_name)) > 0
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.subdomain.zone_id
}

# Validate certs. This will fail on a non-route53 domain
resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = []
  depends_on = [
    aws_route53_record.site_val_record
  ]

  timeouts {
    create = "10m"
  }
}
