# Changelog

All notable changes follow [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and semantic versioning.

## [Unreleased]

## [1.0.1] - 2026-10-06

### Fixed

- Run release-gate contract tests on Terraform 1.8.5, matching the root quality
  job and its `override_module` test semantics.

## [1.0.0] - 2026-10-06

### Added

- Initial edge web application composition using immutable S3, ACM, CloudFront, WAF, KMS, and Route 53 leaf pins.
- Private OAC origin, dual-stack aliases, DNS validation, WAF managed rules and rate limiting, encrypted request logs, access-log retention, account/zone guards, tests, examples, and reusable CI/release workflows.
- CloudFront security response headers on every cache behavior through the pinned leaf module's secure default.
