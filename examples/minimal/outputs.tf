output "url" {
  description = "Application URL."
  value       = module.storefront.url
}

output "origin_bucket" {
  description = "Asset destination."
  value       = module.storefront.origin_bucket
}
