# 1. Private, versioned origin. Its bucket policy is attached after CloudFront
# exists, because the least-privilege OAC statement is scoped to the exact
# distribution ARN. Keeping policy ownership here breaks the otherwise
# unavoidable bucket -> distribution -> bucket-policy dependency cycle.
module "origin_bucket" {
  source = "git::https://github.com/hatan4ik/aws.modules.s3.git?ref=d71da6cd3a3a13bb5fba896c4b1b67da9674b2f9" # immutable main, release pending

  bucket        = var.buckets.origin
  force_destroy = var.force_destroy
  sse_algorithm = "AES256"
  tags          = var.tags

  deny_insecure_transport         = false
  deny_unencrypted_object_uploads = false

  lifecycle_rules = {
    stale-versions = {
      noncurrent_version_expiration          = { noncurrent_days = 90 }
      abort_incomplete_multipart_upload_days = 7
    }
  }
}

# CloudFront standard logging still requires an ACL-enabled S3 bucket. Public
# access remains blocked by the leaf module; BucketOwnerPreferred plus a
# private ACL allows CloudFront's log-delivery canonical user to be granted by
# the service without making objects public.
module "access_logs_bucket" {
  source = "git::https://github.com/hatan4ik/aws.modules.s3.git?ref=d71da6cd3a3a13bb5fba896c4b1b67da9674b2f9" # immutable main, release pending

  bucket           = var.buckets.access_logs
  force_destroy    = var.force_destroy
  object_ownership = "BucketOwnerPreferred"
  sse_algorithm    = "AES256"
  tags             = var.tags

  lifecycle_rules = {
    retention = {
      expiration                             = { days = var.access_log_retention_days }
      noncurrent_version_expiration          = { noncurrent_days = 30 }
      abort_incomplete_multipart_upload_days = 7
    }
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket = module.access_logs_bucket.id
  acl    = "private"

  depends_on = [module.access_logs_bucket]
}

# 2. Global-service prerequisites. These modules use resource-level Region
# placement, so the caller's default provider remains in the workload Region.
module "certificate" {
  source = "git::https://github.com/hatan4ik/aws.modules.acm.git?ref=b42bd50a7c53444dfbd7c6c9a86581c19988f1b5" # merged PR #7, release pending

  domain_name               = var.domain.name
  subject_alternative_names = var.domain.subject_alternative_names
  region                    = "us-east-1"
  route53_zones             = { (var.domain.zone_name) = { zone_id = var.domain.zone_id } }
  tags                      = var.tags
}

module "waf_log_key" {
  source = "git::https://github.com/hatan4ik/aws.modules.kms.git?ref=a7578fe29325840faad31bd7bd52cbf71a6f233f"

  description = "${var.name} CloudFront WAF request logs"
  region      = "us-east-1"
  account_id  = var.account_id
  partition   = "aws"
  aliases     = ["edge/${var.name}/waf-logs"]
  tags        = var.tags

  service_grants = {
    WafRequestLogs = {
      service      = "cloudwatch-logs"
      resource_arn = local.waf_log_group_arn
    }
  }
}

resource "aws_cloudwatch_log_group" "waf" {
  region            = "us-east-1"
  name              = local.waf_log_group_name
  retention_in_days = var.waf_log_retention_days
  kms_key_id        = module.waf_log_key.arn
  tags              = var.tags
}

module "waf" {
  source = "git::https://github.com/hatan4ik/aws.modules.waf.git?ref=78c2fc650b8c803586ab4f1a9295056c8235db4c" # immutable main, v2 release pending

  name   = var.name
  scope  = "CLOUDFRONT"
  region = "us-east-1"
  tags   = var.tags

  managed_rule_groups = var.waf.managed_rule_groups
  rate_based_rules = {
    per-ip = {
      limit    = var.waf.rate_limit
      priority = 40
      action   = "block"
    }
  }

  logging_configuration = {
    log_destination_arn = aws_cloudwatch_log_group.waf.arn
    redacted_fields     = ["authorization", "cookie"]
  }
}

# 3. Distribution. Every sibling contract is passed directly: no jsondecode,
# hand-written IAM statement, ARN surgery, or provider alias.
module "distribution" {
  source = "git::https://github.com/hatan4ik/aws.modules.cloudfront.git?ref=e502e14fd44cedb7833bc1f74fc328184c88a4a8" # immutable main, v2 release pending

  name        = var.name
  aliases     = local.aliases
  price_class = var.price_class
  tags        = var.tags

  minimum_protocol_version = "TLSv1.2_2021"
  geo_restriction          = var.geo_restriction

  origin = {
    bucket_name                 = module.origin_bucket.id
    bucket_regional_domain_name = module.origin_bucket.bucket_regional_domain_name
  }

  viewer_certificate_arn = module.certificate.validated_arn
  web_acl_arn            = module.waf.web_acl_arn
  custom_error_responses = local.custom_error_responses

  logging = {
    bucket_domain_name = module.access_logs_bucket.bucket_domain_name
    prefix             = "cloudfront/${var.name}"
  }

  depends_on = [aws_s3_bucket_acl.cloudfront_logs]
}

# 4. Attach the exact OAC read grant and the platform's TLS/encryption upload
# guardrails after the distribution ARN exists. This pure renderer is the same
# contract the S3 leaf uses internally.
module "origin_bucket_policy" {
  source = "git::https://github.com/hatan4ik/aws.modules.s3.git//modules/bucket-policy?ref=d71da6cd3a3a13bb5fba896c4b1b67da9674b2f9" # immutable main, release pending

  bucket_arn                      = module.origin_bucket.arn
  statements                      = module.distribution.required_bucket_policy_statement
  deny_insecure_transport         = true
  deny_unencrypted_object_uploads = true
  required_sse_algorithm          = "AES256"
}

resource "aws_s3_bucket_policy" "origin" {
  bucket = module.origin_bucket.id
  policy = module.origin_bucket_policy.json
}

# 5. Publish dual-stack aliases only after CloudFront exposes its immutable
# target contract. The zone itself remains owned by the environment.
module "dns" {
  source = "git::https://github.com/hatan4ik/aws.modules.route53.git//modules/records?ref=cf1cfadeac17bfc0a7a8bdb502d3ea3228160d1d" # immutable main, release pending

  zone_id = var.domain.zone_id
  records = local.dns_records

  depends_on = [terraform_data.blueprint_contract]
}
