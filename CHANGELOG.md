# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and semantic versioning.

## [Unreleased]

### Added

- Initial edge web application composition using immutable S3, ACM, CloudFront, WAF, KMS, and Route 53 leaf pins.
- Private OAC origin, dual-stack aliases, DNS validation, WAF managed rules and rate limiting, encrypted request logs, access-log retention, account/zone guards, tests, examples, and reusable CI/release workflows.
- CloudFront security response headers on every cache behavior through the pinned leaf module's secure default.
