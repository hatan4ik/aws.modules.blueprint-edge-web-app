variable "name" {
  description = "Stable application name used for CloudFront, WAF, KMS, logs, and tags."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.name))
    error_message = "name must be 3-32 lowercase letters, digits, or hyphens, starting with a letter and ending with a letter or digit."
  }
}

variable "account_id" {
  description = "Twelve-digit AWS account ID. It scopes the WAF-log KMS policy and is verified against the active provider identity."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "account_id must be exactly twelve digits."
  }
}

variable "buckets" {
  description = "Globally unique S3 bucket names for private application content and CloudFront standard access logs."
  type = object({
    origin      = string
    access_logs = string
  })
  nullable = false

  validation {
    condition = alltrue([
      for bucket in [var.buckets.origin, var.buckets.access_logs] :
      can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", bucket)) &&
      !can(regex("[.][.]", bucket)) &&
      !can(regex("^[0-9]+[.][0-9]+[.][0-9]+[.][0-9]+$", bucket))
    ])
    error_message = "Both bucket names must follow S3 general-purpose bucket naming rules."
  }

  validation {
    condition     = var.buckets.origin != var.buckets.access_logs
    error_message = "The origin and access-log buckets must be different."
  }
}

variable "domain" {
  description = "Route 53 zone and CloudFront aliases. Every alias must be the zone apex, a child of it, or a wildcard child."
  type = object({
    name                      = string
    zone_name                 = string
    zone_id                   = string
    subject_alternative_names = optional(set(string), [])
  })
  nullable = false

  validation {
    condition = (
      can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?[.])+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.domain.name)) &&
      can(regex("^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?[.])+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", var.domain.zone_name)) &&
      can(regex("^Z[0-9A-Z]{1,31}$", var.domain.zone_id))
    )
    error_message = "domain.name and zone_name must be lowercase fully qualified names without a trailing dot; zone_id must be a Route 53 hosted-zone ID."
  }

  validation {
    condition = alltrue([
      for alias in var.domain.subject_alternative_names :
      can(regex("^(\\*[.])?([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?[.])+[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$", alias))
    ])
    error_message = "Every subject alternative name must be a lowercase FQDN, optionally with a wildcard first label."
  }
}

variable "waf" {
  description = "Global WAF posture. Rate limit is requests per source IP in a trailing five-minute window."
  type = object({
    rate_limit = optional(number, 2000)
    managed_rule_groups = optional(map(object({
      name            = string
      vendor_name     = optional(string, "AWS")
      priority        = number
      override_action = optional(string, "none")
      })), {
      common     = { name = "AWSManagedRulesCommonRuleSet", priority = 10 }
      bad_inputs = { name = "AWSManagedRulesKnownBadInputsRuleSet", priority = 20 }
      reputation = { name = "AWSManagedRulesAmazonIpReputationList", priority = 30 }
    })
  })
  default  = {}
  nullable = false

  validation {
    condition     = var.waf.rate_limit >= 10 && var.waf.rate_limit <= 2000000000 && floor(var.waf.rate_limit) == var.waf.rate_limit
    error_message = "waf.rate_limit must be a whole number between 10 and 2000000000."
  }
}

variable "price_class" {
  description = "CloudFront edge footprint. PriceClass_100 covers the US, Canada, and Europe."
  type        = string
  default     = "PriceClass_100"
  nullable    = false

  validation {
    condition     = contains(["PriceClass_100", "PriceClass_200", "PriceClass_All"], var.price_class)
    error_message = "price_class must be PriceClass_100, PriceClass_200, or PriceClass_All."
  }
}

variable "geo_restriction" {
  description = "CloudFront geographic access boundary. The secure platform default admits viewers in the United States only; explicitly widen it when the application's approved data-residency and threat model allows additional countries."
  type = object({
    restriction_type = optional(string, "whitelist")
    locations        = optional(set(string), ["US"])
  })
  default  = {}
  nullable = false

  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction.restriction_type)
    error_message = "geo_restriction.restriction_type must be none, whitelist, or blacklist."
  }

  validation {
    condition     = var.geo_restriction.restriction_type == "none" ? length(var.geo_restriction.locations) == 0 : length(var.geo_restriction.locations) > 0
    error_message = "geo_restriction.locations must be empty for none and non-empty for whitelist or blacklist."
  }

  validation {
    condition     = alltrue([for code in var.geo_restriction.locations : can(regex("^[A-Z]{2}$", code))])
    error_message = "Every geo restriction location must be an uppercase ISO 3166-1 alpha-2 code such as US."
  }
}

variable "spa_error_rewrites" {
  description = "Rewrite S3 403 and 404 responses to /index.html with 200 for a client-routed single-page application."
  type        = bool
  default     = true
  nullable    = false
}

variable "access_log_retention_days" {
  description = "Days CloudFront standard access logs remain in S3."
  type        = number
  default     = 365
  nullable    = false

  validation {
    condition     = var.access_log_retention_days >= 30 && floor(var.access_log_retention_days) == var.access_log_retention_days
    error_message = "access_log_retention_days must be a whole number of at least 30."
  }
}

variable "waf_log_retention_days" {
  description = "CloudWatch Logs retention for full WAF request logs."
  type        = number
  default     = 365
  nullable    = false

  validation {
    condition     = contains([30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.waf_log_retention_days)
    error_message = "waf_log_retention_days must be a supported CloudWatch Logs retention period of at least 30 days."
  }
}

variable "force_destroy" {
  description = "Allow destroy to empty both buckets, including object versions. Keep false outside disposable environments."
  type        = bool
  default     = false
  nullable    = false
}

variable "tags" {
  description = "Ownership and allocation tags applied across every composed module and glue resource."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for key in keys(var.tags) : !startswith(lower(key), "aws:")])
    error_message = "tags must not use the reserved aws: prefix."
  }
}
