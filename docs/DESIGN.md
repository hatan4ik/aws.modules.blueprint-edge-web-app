# Edge web application blueprint design

## Decision

This repository is the composition root for one public static web application. It owns the glue and a small set of composition resources; reusable behavior stays in the leaf repositories.

| Concern | Owner |
| --- | --- |
| Origin and log buckets, policy rendering | `aws.modules.s3` |
| Viewer certificate and DNS validation | `aws.modules.acm` |
| Distribution and Origin Access Control | `aws.modules.cloudfront` |
| Web ACL and logging attachment | `aws.modules.waf` |
| WAF-log encryption key and scoped service grant | `aws.modules.kms` |
| Alias records | `aws.modules.route53//modules/records` |
| WAF log group, access-log ACL, final origin policy, cross-module guards | this blueprint |

Every leaf source is pinned to an immutable commit. A leaf-pin change is a blueprint release and requires a reviewed plan because it can change defaults or resource behavior.

## Dependency order

1. Create the private origin and access-log buckets.
2. Request and DNS-validate the ACM certificate in `us-east-1`.
3. Create a `us-east-1` KMS key, CloudWatch log group, and CloudFront-scope WAF.
4. Create CloudFront using the certificate, WAF, private origin, and log bucket.
5. Render and attach an origin policy scoped to the now-known distribution ARN.
6. Publish Route 53 A and AAAA aliases to the distribution.

The origin bucket is created without its final policy because CloudFront needs the bucket domain while the least-privilege bucket policy needs the distribution ARN. Policy ownership is moved to the composition root to break that cycle without wildcarding `AWS:SourceArn`.

## Region model

CloudFront viewer certificates and CloudFront-scope WAF resources belong in `us-east-1`. The ACM, WAF, KMS, and CloudWatch resources use provider-supported resource-level `region` arguments. S3 remains in the caller's configured workload region. No provider alias is required, so a caller cannot accidentally omit an alias and place a global prerequisite in the wrong region.

## Security boundaries

- S3 Block Public Access remains enabled on both buckets.
- Origin reads are limited to `cloudfront.amazonaws.com` and the exact distribution ARN.
- Every CloudFront cache behavior inherits AWS's managed SecurityHeadersPolicy unless the leaf contract is explicitly overridden.
- TLS and encrypted-upload deny statements apply to the origin policy.
- WAF request logs use a dedicated KMS key whose policy grant is limited to the exact log group ARN.
- CloudFront admits United States viewer locations by default; changing the allowlist is an explicit environment decision.
- Request-log redaction covers credentials commonly carried in `Authorization` and `Cookie`; applications must avoid secrets in query strings and other headers.
- DNS names must remain in the supplied hosted zone; the active account must match `account_id`.
- Destructive bucket emptying is an explicit, warning-producing opt-in.

S3-managed AES-256 is intentional for the CloudFront origin and delivery-log buckets. It avoids a circular distribution/key-policy dependency, supports native CloudFront log delivery, and still provides encryption at rest. The security-sensitive WAF request log group uses a customer-managed key and exact service grant.

## Failure modes

| Symptom | Likely cause and action |
| --- | --- |
| Certificate waits until timeout | The zone ID is wrong, delegation is missing, or an existing CNAME conflicts. Verify Route 53 delegation and the ACM validation records. |
| Distribution creation rejects the certificate or WAF | A prerequisite is outside `us-east-1` or belongs to another account. This blueprint pins their region; verify account credentials and imported state. |
| CloudFront log delivery fails | The access-log bucket ownership/ACL was changed. Keep `BucketOwnerPreferred` and the private ACL. |
| Origin returns 403 | Content is absent, the requested key differs by case, or the exact OAC statement was removed. Inspect the rendered bucket policy and object key. |
| SPA routes return the index document unexpectedly | `spa_error_rewrites` maps all origin 403/404 responses to `/index.html`. Disable it for non-SPA sites or APIs. |
| Destroy stops on non-empty buckets | Expected with `force_destroy = false`. Archive content and explicitly opt in only when deletion is intended. |

## Deliberately out of scope

- Application builds, S3 uploads, cache invalidations, canary release logic, and synthetic tests.
- API Gateway, ALB, ECS, Lambda, Cognito, databases, and regional disaster recovery.
- Route 53 hosted-zone creation and domain registration.
- AWS Organizations, SCPs, state backends, and CI OIDC roles.
- Shield Advanced and Firewall Manager, which are organization-level controls.

## Testing

The contract tests override expensive child modules and assert the composition: encryption/versioning contract, exact three-statement origin policy, global log placement and retention, private ACL, URL/region outputs, SPA behavior, account guard, zone guard, duplicate-bucket rejection, and WAF minimum. Terraform 1.8+ is used for `terraform test`; Terraform 1.7.5 separately initializes and validates the real module to enforce the declared consumer floor.
