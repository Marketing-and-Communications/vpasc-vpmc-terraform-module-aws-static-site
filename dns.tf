data "aws_route53_zone" "route53_tld" {
  provider     = aws.dns
  name         = "${var.route53_tld}."
  private_zone = false
}

data "aws_route53_zone" "subdomain" {
  provider     = aws.dns
  name         = var.site_settings.route53_domain
  private_zone = false
}

resource "aws_route53_record" "site_record" {
  provider = aws.dns
  zone_id  = data.aws_route53_zone.subdomain.zone_id
  name     = local.domain
  type     = "CNAME"
  ttl      = "30"
  records  = [aws_cloudfront_distribution.site.domain_name]
}