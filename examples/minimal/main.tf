module "storefront" {
  source = "../.."

  name       = "storefront"
  account_id = var.account_id
  buckets = {
    origin      = "storefront-assets-${var.account_id}"
    access_logs = "storefront-cloudfront-logs-${var.account_id}"
  }
  domain = {
    name      = "app.${var.zone_name}"
    zone_name = var.zone_name
    zone_id   = var.zone_id
  }
  tags = { Environment = "sandbox", ManagedBy = "Terraform" }
}
