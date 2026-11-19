#!/usr/bin/env bash
# Runs `terraform plan` against an example with dummy inputs and fails only on
# errors raised inside `variable` validation blocks. Provider/auth errors are
# expected (there are no credentials in CI) and are ignored.
#
# Usage: check-variable-validation.sh <example-dir>
set -euo pipefail

dir="$1"
cd "$dir"

# Don't leave artifacts behind when run locally.
trap 'rm -rf ci-validation.auto.tfvars .terraform .terraform.lock.hcl' EXIT

cat > ci-validation.auto.tfvars <<'EOF'
registration_name             = "ci-validation"
registration_type             = "organization"
organization_id               = "123456789012"
infra_project_id              = "ci-test-project"
infrastructure_manager_region = "us-central1"
deployment_method             = "infrastructure-manager"
role_arn                      = "arn:aws:sts::111111111111:assumed-role/CrowdStrikeCSPMConnector"
# Optional inputs (wif_project_id, resource_prefix, resource_suffix) are
# intentionally unset -> null. Infrastructure Manager submits empty console
# fields as unset, and Terraform 1.5.7 (the IM default) does not short-circuit
# `||`, so validations must not call length() on a possibly-null value.
EOF

# falcon_client_id must be 32 hex characters. Build a placeholder at runtime
# rather than writing a credential-shaped literal, which secret scanners flag.
# falcon_client_secret is left unset, as in the generated IM inputs: the module
# then reads it from Secret Manager, which fails auth like every other call.
TF_VAR_falcon_client_id=$(printf 'a%.0s' {1..32})
export TF_VAR_falcon_client_id

terraform init -backend=false -input=false >/dev/null

# Dummy credentials let the providers configure so plan reaches variable
# evaluation; every API call afterwards fails with a 401, which we filter out.
export GOOGLE_OAUTH_ACCESS_TOKEN=dummy GOOGLE_PROJECT=ci-test-project

# plan always exits non-zero here (auth errors), so don't let pipefail abort.
errors=$( (terraform plan -input=false -refresh=false -lock=false -json 2>/dev/null || true) | jq -r '
  select(.type == "diagnostic"
         and .diagnostic.severity == "error"
         and ((.diagnostic.snippet.context // "") | startswith("variable ")))
  | "\(.diagnostic.range.filename):\(.diagnostic.range.start.line) [\(.diagnostic.snippet.context)] \(.diagnostic.summary): \(.diagnostic.detail)"')

if [[ -n "$errors" ]]; then
  echo "::error::Variable validation failed on Terraform $(terraform version -json | jq -r .terraform_version) in $dir"
  echo "$errors"
  exit 1
fi
echo "No variable validation errors in $dir"
