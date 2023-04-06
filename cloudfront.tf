locals {
  aliases = distinct(concat(
    [local.domain],
    var.site_settings.top_level_domain == "" || var.deployment != "prod" ? [] : [var.site_settings.top_level_domain],
    var.site_settings.additional_domains == null ? tolist([]) : tolist(var.site_settings.additional_domains),
    try(var.site_settings.additional_cloudfront_aliases, tolist([]))
  ))
}


resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Static Website + Lambda@Edge (${var.deployment})"
  aliases             = local.aliases
  default_root_object = "index.html"


  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = var.minimum_protocol_version
  }

  origin {
    domain_name = aws_s3_bucket.bucket.bucket_domain_name
    origin_id   = aws_s3_bucket.bucket.id
    custom_origin_config {
      http_port              = "80"
      https_port             = "443"
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = var.origin_ssl_protocols
    }
    custom_header {
      name  = "rules-cache-timeout"
      value = try(var.site_settings.rules_cache_timeout, var.rules_cache_timeout)
    }

    custom_header {
      name  = "rules-url"
      value = try(var.site_settings.rewrite_rules_location, var.rewrite_rules_location)
    }
  }

  custom_error_response {
    error_code         = 404
    response_code      = 404
    response_page_path = try(var.site_settings.error_response_404_path, var.error_response_404_path)
  }

  custom_error_response {
    error_code         = 403
    response_code      = 403
    response_page_path = try(var.site_settings.error_response_403_path, var.error_response_403_path)
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = true
      # Include query strings, but don't use them for caching
      query_string_cache_keys = []

      cookies {
        forward = "none"
      }
    }
    compress               = true
    viewer_protocol_policy = "redirect-to-https"

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge_rewrite.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.edge_security.qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.enable_hostname_rewrites ? toset([0]) : toset([])

      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_host_header[0].qualified_arn
        include_body = false
      }
    }

    min_ttl     = try(var.site_settings.min_ttl, var.min_ttl)
    default_ttl = try(var.site_settings.default_ttl, var.default_ttl)
    max_ttl     = try(var.site_settings.max_ttl, var.max_ttl)
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern     = "index.html"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false
      headers      = ["Origin"]

      cookies {
        forward = "none"
      }
    }

    min_ttl                = try(var.site_settings.index_ttl, var.index_ttl)
    default_ttl            = try(var.site_settings.index_ttl, var.index_ttl)
    max_ttl                = try(var.site_settings.index_ttl, var.index_ttl)
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 1
  ordered_cache_behavior {
    path_pattern     = "*.html"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge_rewrite.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.edge_security.qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.enable_hostname_rewrites ? toset([0]) : toset([])

      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_host_header[0].qualified_arn
        include_body = false
      }
    }

    min_ttl                = try(var.site_settings.html_ttl, var.html_ttl)
    default_ttl            = try(var.site_settings.html_ttl, var.html_ttl)
    max_ttl                = try(var.site_settings.html_ttl, var.html_ttl)
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 2
  ordered_cache_behavior {
    path_pattern     = "*.css"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge_rewrite.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.edge_security.qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.enable_hostname_rewrites ? toset([0]) : toset([])

      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_host_header[0].qualified_arn
        include_body = false
      }
    }

    min_ttl                = try(var.site_settings.css_ttl, var.css_ttl)
    default_ttl            = try(var.site_settings.css_ttl, var.css_ttl)
    max_ttl                = try(var.site_settings.css_ttl, var.css_ttl)
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 3
  ordered_cache_behavior {
    path_pattern     = "*.js"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge_rewrite.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.edge_security.qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.enable_hostname_rewrites ? toset([0]) : toset([])

      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_host_header[0].qualified_arn
        include_body = false
      }
    }

    min_ttl                = try(var.site_settings.javascript_ttl, var.javascript_ttl)
    default_ttl            = try(var.site_settings.javascript_ttl, var.javascript_ttl)
    max_ttl                = try(var.site_settings.javascript_ttl, var.javascript_ttl)
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 4
  ordered_cache_behavior {
    path_pattern     = "*.jpg"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge_rewrite.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.edge_security.qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.enable_hostname_rewrites ? toset([0]) : toset([])

      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_host_header[0].qualified_arn
        include_body = false
      }
    }

    min_ttl                = try(var.site_settings.media_ttl, var.media_ttl)
    default_ttl            = try(var.site_settings.media_ttl, var.media_ttl)
    max_ttl                = try(var.site_settings.media_ttl, var.media_ttl)
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 5
  ordered_cache_behavior {
    path_pattern     = "*.png"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge_rewrite.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.edge_security.qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.enable_hostname_rewrites ? toset([0]) : toset([])

      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_host_header[0].qualified_arn
        include_body = false
      }
    }

    min_ttl                = try(var.site_settings.media_ttl, var.media_ttl)
    default_ttl            = try(var.site_settings.media_ttl, var.media_ttl)
    max_ttl                = try(var.site_settings.media_ttl, var.media_ttl)
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 6
  ordered_cache_behavior {
    path_pattern     = "*.gif"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge_rewrite.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.edge_security.qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.enable_hostname_rewrites ? toset([0]) : toset([])

      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_host_header[0].qualified_arn
        include_body = false
      }
    }

    min_ttl                = try(var.site_settings.media_ttl, var.media_ttl)
    default_ttl            = try(var.site_settings.media_ttl, var.media_ttl)
    max_ttl                = try(var.site_settings.media_ttl, var.media_ttl)
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 7
  ordered_cache_behavior {
    path_pattern     = "*.svg"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge_rewrite.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.edge_security.qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.enable_hostname_rewrites ? toset([0]) : toset([])

      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_host_header[0].qualified_arn
        include_body = false
      }
    }

    min_ttl                = try(var.site_settings.media_ttl, var.media_ttl)
    default_ttl            = try(var.site_settings.media_ttl, var.media_ttl)
    max_ttl                = try(var.site_settings.media_ttl, var.media_ttl)
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior with precedence 8
  ordered_cache_behavior {
    path_pattern     = "*.pdf"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.bucket.id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn   = aws_lambda_function.edge_rewrite.qualified_arn
      include_body = false
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn   = aws_lambda_function.edge_security.qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.enable_hostname_rewrites ? toset([0]) : toset([])

      content {
        event_type   = "viewer-request"
        lambda_arn   = aws_lambda_function.edge_host_header[0].qualified_arn
        include_body = false
      }
    }

    min_ttl                = try(var.site_settings.pdf_ttl, var.pdf_ttl)
    default_ttl            = try(var.site_settings.pdf_ttl, var.pdf_ttl)
    max_ttl                = try(var.site_settings.pdf_ttl, var.pdf_ttl)
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.bucket_logging.bucket_domain_name
    prefix          = var.deployment
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}


resource "aws_cloudfront_response_headers_policy" "site" {
  name = "site-headers-policy-${var.deployment}"

  custom_headers_config {
    items {
      header   = "rules-cache-timeout"
      override = true
      value    = var.rules_cache_timeout
    }

    items {
      header   = "rules-url"
      override = true
      value    = try(var.site_settings.rewrite_rules_location, var.rewrite_rules_location)
    }
  }
}

