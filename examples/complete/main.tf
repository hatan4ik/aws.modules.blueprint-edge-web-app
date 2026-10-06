module "storefront" {
  source = "../.."

  name       = "storefront"
  account_id = var.account_id
  buckets = {
    origin      = "storefront-assets-${var.account_id}"
    access_logs = "storefront-cloudfront-logs-${var.account_id}"
  }
  domain = {
    name                      = "app.${var.zone_name}"
    zone_name                 = var.zone_name
    zone_id                   = var.zone_id
    subject_alternative_names = ["www.${var.zone_name}"]
  }

  price_class               = "PriceClass_100"
  access_log_retention_days = 730
  waf_log_retention_days    = 731
  waf = {
    rate_limit = 1000
    managed_rule_groups = {
      common     = { name = "AWSManagedRulesCommonRuleSet", priority = 10 }
      bad_inputs = { name = "AWSManagedRulesKnownBadInputsRuleSet", priority = 20 }
      reputation = { name = "AWSManagedRulesAmazonIpReputationList", priority = 30 }
      sql        = { name = "AWSManagedRulesSQLiRuleSet", priority = 35 }
    }
  }
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
    Owner       = "web-platform"
    CostCenter  = "digital"
  }
}
