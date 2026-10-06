output "url" {
  description = "Application URL."
  value       = module.storefront.url
}

output "distribution" {
  description = "CloudFront identifiers."
  value       = module.storefront.distribution
}

output "web_acl" {
  description = "WAF and encrypted log identifiers."
  value       = module.storefront.web_acl
}
