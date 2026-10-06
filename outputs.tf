output "url" {
  description = "Canonical HTTPS application URL."
  value       = "https://${var.domain.name}"
}

output "distribution" {
  description = "CloudFront identifiers for deployments, invalidations, monitoring, and incident response."
  value = {
    id             = module.distribution.distribution_id
    arn            = module.distribution.distribution_arn
    domain_name    = module.distribution.domain_name
    hosted_zone_id = module.distribution.hosted_zone_id
  }
}

output "origin_bucket" {
  description = "Private origin bucket identity used by the application asset pipeline."
  value = {
    id     = module.origin_bucket.id
    arn    = module.origin_bucket.arn
    region = module.origin_bucket.region
  }
}

output "access_log_bucket" {
  description = "CloudFront standard access-log bucket."
  value = {
    id  = module.access_logs_bucket.id
    arn = module.access_logs_bucket.arn
  }
}

output "certificate_arn" {
  description = "Validated us-east-1 ACM viewer certificate ARN."
  value       = module.certificate.validated_arn
}

output "web_acl" {
  description = "Global WAF identity and full-request log destination."
  value = {
    arn            = module.waf.web_acl_arn
    id             = module.waf.web_acl_id
    capacity       = module.waf.web_acl_capacity
    log_group_name = aws_cloudwatch_log_group.waf.name
    log_group_arn  = aws_cloudwatch_log_group.waf.arn
    kms_key_arn    = module.waf_log_key.arn
  }
}

output "dns_record_fqdns" {
  description = "Route 53 A and AAAA alias record FQDNs keyed by stable record key."
  value       = module.dns.fqdns
}

output "workload_region" {
  description = "Region of the default AWS provider, which owns both S3 buckets."
  value       = data.aws_region.current.region
}
