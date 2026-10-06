variable "aws_region" {
  description = "Workload region for the S3 buckets."
  type        = string
  default     = "us-east-2"
}

variable "account_id" {
  description = "AWS account ID."
  type        = string
}

variable "zone_id" {
  description = "Existing public Route 53 hosted-zone ID."
  type        = string
}

variable "zone_name" {
  description = "Hosted-zone name."
  type        = string
}
