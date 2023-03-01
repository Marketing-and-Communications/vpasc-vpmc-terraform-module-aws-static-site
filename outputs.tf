output "aws_iam_access_key_id" {
  value     = aws_iam_access_key.key.id
  sensitive = true
}

output "aws_iam_access_key_secret" {
  value     = aws_iam_access_key.key.secret
  sensitive = true
}

output "cloudfront_aliases" {
  value = aws_cloudfront_distribution.site.aliases
}
