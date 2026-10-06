# Minimal example

Required account, hosted-zone, and bucket inputs with the blueprint defaults. Supply values through your environment root; do not commit tfvars containing environment data.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.35.0, < 7.0.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_storefront"></a> [storefront](#module\_storefront) | ../.. | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS account ID. | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | Workload region for the S3 buckets. | `string` | `"us-east-2"` | no |
| <a name="input_zone_id"></a> [zone\_id](#input\_zone\_id) | Existing public Route 53 hosted-zone ID. | `string` | n/a | yes |
| <a name="input_zone_name"></a> [zone\_name](#input\_zone\_name) | Hosted-zone name. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_origin_bucket"></a> [origin\_bucket](#output\_origin\_bucket) | Asset destination. |
| <a name="output_url"></a> [url](#output\_url) | Application URL. |
<!-- END_TF_DOCS -->
