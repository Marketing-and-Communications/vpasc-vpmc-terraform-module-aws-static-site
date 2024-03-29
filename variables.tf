variable "additional_certs" {
  type        = list(any)
  description = "Additional SANs that will be added to the generated ACM certificate"
  default     = []
}

variable "additional_cloudfront_aliases" {
  type        = list(any)
  description = "Additional aliases that will be added to CloudFront without being added as cert SANs"
  default     = []
}

variable "allow_bucket_force_destroy" {
  type        = bool
  description = "Allow buckets to be destroyed when doing a terraform destroy"
  default     = false
}

variable "aws_account_name" {
  type        = string
  description = "Name of the AWS account where this site lives"
}

variable "css_ttl" {
  type        = number
  description = "The number of seconds to cache CSS content"
  default     = 2592000
}

variable "def_html_ttl" {
  type        = number
  description = "The number of seconds to cache HTML content"
  default     = 1801
}

variable "default_ttl" {
  type        = number
  description = "Default number of seconds to cache content"
  default     = 60
}

variable "deployment" {
  description = "The deployment environment, i.e. dev, staging, prod"
  type        = string
  nullable    = false
}

variable "error_response_403_path" {
  type        = string
  description = "The location of the 403 error page"
  default     = "/error/403.html"
}

variable "error_response_404_path" {
  type        = string
  description = "The location of the 404 error page"
  default     = "/error/404.html"
}

# This was moved to lambda.tf so that localstack could use that file independently
#variable "enable_hostname_rewrites" {
#  type        = bool
#  description = "Whether or not to install a viewer lambda to capture the original hostname as an additional header to enable rewrites based on hostname, not just URI"
#  default     = false
#}

variable "global_accelerator_source" {
  description = "The source address for the global accelerator (i.e., tamu.edu). Leave blank to not use a GA"
  type        = string
  default     = ""
}

variable "global_accelerator_target" {
  description = "The target address for the global accelerator (i.e., www.tamu.edu). Leave blank to not use a GA"
  type        = string
  default     = ""
}

variable "html_ttl" {
  type        = number
  description = "The number of seconds to cache .html files (except for index.html)"
  default     = 1876
}

variable "index_ttl" {
  type        = number
  description = "The number of seconds to cache index.html content"
  default     = 60
}

variable "javascript_ttl" {
  type        = number
  description = "The number of seconds to cache JavaScript content"
  default     = 2592000
}

# This was moved to lambda.tf so that localstack could use that file independently
#variable "lambda_runtime" {
#  type        = number
#  description = "The node.js runtime version to use for the lambda@edge function"
#  default     = 16
#}

variable "log_expiration" {
  type        = number
  description = "The number of days to retain logs"
  default     = 365
}

variable "max_ttl" {
  type        = number
  description = "Maximum number of seconds to cache content"
  default     = 259200
}

variable "media_ttl" {
  type        = number
  description = "The number of seconds to cache media content"
  default     = 86400
}

variable "min_ttl" {
  type        = number
  description = "Minimum number of seconds to cache content"
  default     = 0
}

variable "minimum_protocol_version" {
  type        = string
  description = "A version string representing the minimum TLS version (https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/secure-connections-supported-viewer-protocols-ciphers.html)"
  default     = "TLSv1.2_2021"
}

variable "onepassword_url" {
  type        = string
  description = "The URL to the 1password connect API server"
  default     = "http://localhost:8080"
}

variable "onepassword_vault" {
  type        = string
  description = "The name of the 1password vault where S3 keys will be stored"
  default     = "it-svc-aws-static-sites"
}

variable "origin_ssl_protocols" {
  type        = list(any)
  description = "The TLS versions supported by the origin"
  default     = ["TLSv1.2"]
}

variable "pdf_ttl" {
  type        = number
  description = "The number of seconds to cache PDF content"
  default     = 601
}

variable "rewrite_rules_location" {
  type        = string
  description = "The publicly accessible URL of the rewrite rules file"
}

variable "route53_tld" {
  type        = string
  description = "The top level domain in route53 where subdomains are added"
  default     = "cloud.tamu.edu"
}

variable "rules_cache_timeout" {
  type        = number
  description = "The number of seconds to cache rewrite rules"
  default     = 3602
}

# This was moved to lambda.tf so that localstack could use that file independently
#variable "site_settings" {
#  #type        = map(any)
#  description = "A map of site settings that represent user-configurable parameters"
#}
