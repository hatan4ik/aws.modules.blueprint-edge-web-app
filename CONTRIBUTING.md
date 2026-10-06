# Contributing

This repository is a composition root. Put reusable resource behavior in the owning leaf module; changes here should wire leaf contracts, expose a justified golden-path input, or update an immutable leaf pin.

## Local gate

Install Terraform 1.7.5 and 1.8.5, TFLint, terraform-docs v0.20.0, Checkov, and Trivy. Then run:

```sh
make check TEST_TERRAFORM="TFENV_TERRAFORM_VERSION=1.8.5 terraform"
```

Terraform 1.8+ is needed only for contract tests using `override_module`. CI separately validates the root on Terraform 1.7.5, the consumer floor.

## Pull requests

- Use Conventional Commits.
- Add a test for changed behavior.
- Run `make docs` with terraform-docs v0.20.0 and commit generated tables.
- Update `CHANGELOG.md`.
- Review every changed leaf pin for defaults, outputs, checks, state moves, and security impact.
- Never use a floating branch or mutable tag as a module source.

## Releases

Merge the changelog version, create and push a signed annotated semantic-version tag, then dispatch `module-release` with that existing tag. Consumers pin the released commit SHA; tags are never moved or deleted.
