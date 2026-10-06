mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }
  mock_data "aws_region" {
    defaults = { region = "us-east-2" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com" }
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
    name      = "app.example.com"
    zone_name = "example.com"
    zone_id   = "Z0123456789ABCDEF"
  }
}

run "rejects_duplicate_buckets" {
  command = plan
  variables {
    buckets = {
      origin      = "storefront-assets-111122223333"
      access_logs = "storefront-assets-111122223333"
    }
  }
  expect_failures = [var.buckets]
}

run "rejects_an_alias_outside_the_hosted_zone" {
  command = plan
  variables {
    domain = {
      name                      = "app.example.com"
      zone_name                 = "example.com"
      zone_id                   = "Z0123456789ABCDEF"
      subject_alternative_names = ["app.other.example"]
    }
  }
  expect_failures = [terraform_data.blueprint_contract]
}

run "rejects_the_wrong_account_id" {
  command = plan
  variables { account_id = "444455556666" }
  expect_failures = [terraform_data.blueprint_contract]
}

run "rejects_a_rate_limit_below_the_service_minimum" {
  command = plan
  variables { waf = { rate_limit = 9 } }
  expect_failures = [var.waf]
}
