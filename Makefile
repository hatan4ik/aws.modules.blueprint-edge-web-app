SHELL := /bin/bash
.DEFAULT_GOAL := check

ROOT_DIRS     := .
EXAMPLE_DIRS  := $(sort $(patsubst %/,%,$(dir $(wildcard examples/*/*.tf))))
ALL_DIRS      := $(ROOT_DIRS) $(EXAMPLE_DIRS)
TFLINT_CONFIG := $(CURDIR)/.tflint.hcl
TFDOCS_CONFIG := $(CURDIR)/.terraform-docs.yml
TFDOCS_VERSION := v0.20.0
TEST_TERRAFORM ?= terraform

.PHONY: check fmt fmt-fix init validate lint test docs-version docs docs-check security lock clean

check: fmt validate lint test docs-check security

fmt:
	@terraform fmt -check -recursive -diff

fmt-fix:
	@terraform fmt -recursive

init:
	@for dir in $(ALL_DIRS); do \
		echo "==> init $$dir"; \
		(cd "$$dir" && terraform init -backend=false -input=false >/dev/null) || exit 1; \
	done

validate: init
	@for dir in $(ALL_DIRS); do \
		echo "==> validate $$dir"; \
		(cd "$$dir" && terraform validate) || exit 1; \
	done

lint:
	@tflint --init --config="$(TFLINT_CONFIG)"
	@for dir in $(ALL_DIRS); do \
		echo "==> lint $$dir"; \
		(cd "$$dir" && tflint --config="$(TFLINT_CONFIG)" --format compact) || exit 1; \
	done

test:
	@$(TEST_TERRAFORM) version -json | python3 -c 'import json,sys; v=tuple(int(p) for p in json.load(sys.stdin)["terraform_version"].split(".")[:2]); sys.exit(0 if v >= (1, 8) else 1)' || { \
		echo "error: contract tests need Terraform >= 1.8; set TEST_TERRAFORM to a compatible binary" >&2; exit 1; }
	@$(TEST_TERRAFORM) init -backend=false -input=false >/dev/null
	@$(TEST_TERRAFORM) test

docs-version:
	@terraform-docs --version | grep -q "$(TFDOCS_VERSION)" || { \
		echo "error: terraform-docs $(TFDOCS_VERSION) is required" >&2; exit 1; }

docs: docs-version
	@for dir in $(ALL_DIRS); do terraform-docs -c "$(TFDOCS_CONFIG)" "$$dir" || exit 1; done

docs-check: docs-version
	@for dir in $(ALL_DIRS); do terraform-docs -c "$(TFDOCS_CONFIG)" --output-check "$$dir" || exit 1; done

security:
	@checkov -d . --framework terraform --quiet --compact
	@trivy config --severity HIGH,CRITICAL --exit-code 1 .

lock:
	@terraform providers lock -platform=linux_amd64 -platform=linux_arm64 -platform=darwin_amd64 -platform=darwin_arm64

clean:
	@find . -type d -name .terraform -prune -exec rm -rf {} +
	@find . -mindepth 2 -name .terraform.lock.hcl -not -path '*/.terraform/*' -delete
