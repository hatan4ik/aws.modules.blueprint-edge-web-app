mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
      arn        = "arn:aws:iam::111122223333:root"
      user_id    = "111122223333"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "us-east-2"
      name   = "us-east-2"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }
}

override_module {
  target = module.access_logs_bucket
  outputs = {
    id                 = "storefront-cloudfront-logs-111122223333"
    arn                = "arn:aws:s3:::storefront-cloudfront-logs-111122223333"
    bucket_domain_name = "storefront-cloudfront-logs-111122223333.s3.amazonaws.com"
    sse_algorithm      = "AES256"
    versioning         = "Enabled"
  }
}

override_module {
  target = module.certificate
  outputs = {
    validated_arn = "arn:aws:acm:us-east-1:111122223333:certificate/01234567-89ab-cdef-0123-456789abcdef"
  }
}

override_module {
  target = module.distribution
  outputs = {
    distribution_id  = "E1EXAMPLE"
    distribution_arn = "arn:aws:cloudfront::111122223333:distribution/E1EXAMPLE"
    domain_name      = "d111111abcdef8.cloudfront.net"
    hosted_zone_id   = "Z2FDTNDATAQYW2"
    required_bucket_policy_statement = {
      AllowCloudFrontServicePrincipal = {
        effect        = "Allow"
        principals    = { Service = ["cloudfront.amazonaws.com"] }
        principal_all = false
        actions       = ["s3:GetObject"]
        resources     = ["arn:aws:s3:::storefront-assets-111122223333/*"]
        conditions = [{
          test     = "StringEquals"
          variable = "AWS:SourceArn"
          values   = ["arn:aws:cloudfront::111122223333:distribution/E1EXAMPLE"]
        }]
      }
    }
  }
}

variables {
  name       = "storefront"
  account_id = "111122223333"
  buckets = {
    origin      = "storefront-assets-111122223333"
    access_logs = "storefront-cloudfront-logs-111122223333"
  }
  domain = {
    name                      = "app.example.com"
    zone_name                 = "example.com"
    zone_id                   = "Z0123456789ABCDEF"
    subject_alternative_names = ["www.example.com"]
  }
  tags = {
    Environment = "production"
    Owner       = "web-platform"
  }
}

run "plans_the_complete_edge_contract" {
  command = plan

  assert {
    condition = (
      module.origin_bucket.sse_algorithm == "AES256" &&
      module.origin_bucket.versioning == "Enabled" &&
      module.access_logs_bucket.sse_algorithm == "AES256" &&
      module.access_logs_bucket.versioning == "Enabled"
    )
    error_message = "Both edge buckets must be encrypted and versioned."
  }

  assert {
    condition     = module.origin_bucket_policy.statement_count == 3
    error_message = "The origin policy must contain OAC read, TLS-only, and encrypted-upload statements."
  }

  assert {
    condition = (
      aws_cloudwatch_log_group.waf.region == "us-east-1" &&
      aws_cloudwatch_log_group.waf.name == "aws-waf-logs-storefront" &&
      aws_cloudwatch_log_group.waf.retention_in_days == 365
    )
    error_message = "WAF request logs must use the required prefix in us-east-1 with one-year retention."
  }

  assert {
    condition     = aws_s3_bucket_acl.cloudfront_logs.acl == "private"
    error_message = "The legacy CloudFront log-delivery bucket must keep a private ACL."
  }

  assert {
    condition = (
      module.distribution.distribution_id == "E1EXAMPLE" &&
      var.geo_restriction.restriction_type == "whitelist" &&
      var.geo_restriction.locations == toset(["US"])
    )
    error_message = "The edge contract must default to a United States viewer allowlist."
  }

  assert {
    condition     = output.url == "https://app.example.com" && output.workload_region == "us-east-2"
    error_message = "The blueprint must expose the canonical HTTPS URL and workload provider Region."
  }
}

run "disables_spa_rewrites_when_requested" {
  command = plan

  variables { spa_error_rewrites = false }

  assert {
    condition     = length(local.custom_error_responses) == 0
    error_message = "spa_error_rewrites=false must send no custom error response to CloudFront."
  }
}
