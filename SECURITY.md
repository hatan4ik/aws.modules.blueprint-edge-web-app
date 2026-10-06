# Security policy

## Supported versions

The latest released minor line receives security and functional fixes. Unreleased `main` is not supported for production use.

## Reporting

Use GitHub private vulnerability reporting from the repository Security tab. Do not publish a security issue or pull request. Include the exact commit SHA, inputs, resulting plan or policy, and impact.

Security findings include public-origin exposure, a CloudFront OAC policy broader than one distribution, a region/account validation bypass, log encryption or retention regression, WAF removal, sensitive output, destructive behavior enabled by default, or a release pipeline that can publish unsigned/unverified code.

We acknowledge reports within five business days and coordinate remediation before disclosure.
