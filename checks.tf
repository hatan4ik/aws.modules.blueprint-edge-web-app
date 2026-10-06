data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "terraform_data" "blueprint_contract" {
  input = {
    account_id = var.account_id
    aliases    = local.aliases
    zone_name  = var.domain.zone_name
  }

  lifecycle {
    precondition {
      condition     = data.aws_caller_identity.current.account_id == var.account_id
      error_message = "account_id must match the account authenticated by the default AWS provider."
    }

    precondition {
      condition = alltrue([
        for alias in local.aliases :
        trimprefix(alias, "*.") == var.domain.zone_name || endswith(trimprefix(alias, "*."), ".${var.domain.zone_name}")
      ])
      error_message = "Every CloudFront alias must be the Route 53 zone apex or a child of domain.zone_name."
    }
  }
}

check "force_destroy_enabled" {
  assert {
    condition     = !var.force_destroy
    error_message = "force_destroy is enabled for both edge buckets. Use it only for disposable environments; destroy can permanently remove every object version."
  }
}
