locals {
  aliases = setunion([var.domain.name], var.domain.subject_alternative_names)

  waf_log_group_name = "aws-waf-logs-${var.name}"
  waf_log_group_arn  = "arn:aws:logs:us-east-1:${var.account_id}:log-group:${local.waf_log_group_name}"

  dns_records = merge(
    {
      for alias in local.aliases : "a-${substr(sha1(alias), 0, 12)}" => {
        name = alias
        type = "A"
        alias = {
          name                   = module.distribution.domain_name
          zone_id                = module.distribution.hosted_zone_id
          evaluate_target_health = false
        }
      }
    },
    {
      for alias in local.aliases : "aaaa-${substr(sha1(alias), 0, 12)}" => {
        name = alias
        type = "AAAA"
        alias = {
          name                   = module.distribution.domain_name
          zone_id                = module.distribution.hosted_zone_id
          evaluate_target_health = false
        }
      }
    }
  )

  custom_error_responses = var.spa_error_rewrites ? [
    { error_code = 403, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 0 },
    { error_code = 404, response_code = 200, response_page_path = "/index.html", error_caching_min_ttl = 0 },
  ] : []
}
