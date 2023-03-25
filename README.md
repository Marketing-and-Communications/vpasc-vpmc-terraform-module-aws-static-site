# vpasc-vpmc-terraform-module-aws-static-site

Terraform module for creating AWS CloudFront + Lambda@Edge static sites

## Usage

Example usage:

```hcl
module "aws_static_site" {
  source = "https://github.com/Marketing-and-Communications/vpasc-vpmc-terraform-module-aws-static-site?ref=v1.0.0"
  providers = {
    aws = aws,
    "aws.dns" = aws.dns
  }

  aws_account_name        = "my-aws-account"
  deployment              = "dev"
  rewrite_rules_location  = "https://.../rules/rules.json"
  site_settings           = {
    top_level_domain      = "blake-website-test.tamu.edu"
    route53_domain        = "blake-website-test.cloud.tamu.edu"
    additional_domains    = []
  }
```

The `site_settings` line take a dictionary of variable overrides and includes the following:

| Parameter | Default Value | Description |
|-----------|---------------|-------------|
|css_ttl|2592000|The number of seconds to cache CSS content|
|def_html_ttl|1801|The number of seconds to cache HTML content|
|default_ttl|60|Default number of seconds to cache content|
|error_response_403_path|/403.html|The location of the 403 error page|
|error_response_404_path|/404.html|The location of the 404 error page|
|html_ttl|1876|The number of seconds to cache .html files (except for index.html)|
|index_ttl|60|The number of seconds to cache index.html content|
|javascript_ttl|2592000|The number of seconds to cache JavaScript content|
|log_expiration|365|The number of days to retain logs|
|max_ttl|259200|Maximum number of seconds to cache content|
|media_ttl|86400|The number of seconds to cache media content|
|min_ttl|0|Minimum number of seconds to cache content|
|pdf_ttl|601|The number of seconds to cache PDF content|
|rewrite_rules_location||The publicly accessible URL of the rewrite rules file|
|route53_tld|cloud.tamu.edu|The top level domain in route53 where subdomains are added|
|rules_cache_timeout|3602|The number of seconds to cache rewrite rules|

## IAM User Bucket Credentials

Access to IAM user credentials for S3 bucket access is provided through [TAMU's instance of
1password](https://tamu.1password.com). By default, all keys are stored in the
`it-svc-aws-static-sites` vault under the name of the website.

## Releases

1. Create a pull request with a target branch of `main`
2. Tag a release with v1.0.0 (or whatever version) and a workflow will run that updates tags to support semantic versioning in terraform.
