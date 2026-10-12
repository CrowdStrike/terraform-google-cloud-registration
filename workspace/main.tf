locals {
  effective_prefix = var.resource_prefix != null ? var.resource_prefix : ""
  effective_suffix = var.resource_suffix != null ? var.resource_suffix : ""
  # Keyed on the role ARN: with no identity, aws-sts fails in workload-identity before the precondition
  identity_source = var.workspace_role_arn != null ? "aws-sts" : "gcp-oidc"
}

# Stand-in for the provider's Workspace registration resource. Its guards move to it unchanged
resource "terraform_data" "gws_registration" {
  input = {
    id                  = var.gws_registration_id
    wif_pool_id         = var.wif_pool_id
    wif_provider_id     = var.wif_provider_id
    wif_identity_source = var.gws_identity_source
    service_account_id  = var.service_account_id
  }

  lifecycle {
    precondition {
      condition     = (var.workspace_role_arn != null) != (var.workspace_service_account_unique_id != null)
      error_message = "Exactly one of workspace_role_arn or workspace_service_account_unique_id must be provided."
    }

    precondition {
      condition     = length(local.effective_prefix) + length(local.effective_suffix) <= 13
      error_message = "Combined length of resource_prefix and resource_suffix must not exceed 13 characters."
    }

    # self.input: terraform_data has no output before the apply (provider: self.wif_identity_source)
    postcondition {
      condition     = self.input.wif_identity_source == local.identity_source
      error_message = "Identity source mismatch: CrowdStrike API returned '${self.input.wif_identity_source}' but the provided credentials indicate '${local.identity_source}'. Provide workspace_service_account_unique_id for gcp-oidc clouds or workspace_role_arn for aws-sts clouds."
    }
  }
}

# tflint-ignore: terraform_unused_declarations # only checks that the org belongs to the Workspace
data "google_organization" "link_check" {
  organization = "organizations/${var.organization_id}"

  lifecycle {
    postcondition {
      condition     = self.directory_customer_id != ""
      error_message = <<-EOT
        Organization ${var.organization_id} has no Workspace customer ID.
        Give the organization of the Google Workspace in organization_id.
      EOT
    }

    # Google can give the ID with a customers/ prefix and in another case.
    postcondition {
      condition = (
        self.directory_customer_id == "" ||
        lower(trimprefix(self.directory_customer_id, "customers/")) == lower(var.customer_id)
      )
      error_message = <<-EOT
        The Workspace customer ID and the GCP organization do not match.
        Organization ${var.organization_id} belongs to Workspace ${self.directory_customer_id},
        and the registration gives ${var.customer_id}. Correct one of the two values.
      EOT
    }
  }
}

# The Workspace has its own pool, apart from the pool of the Google Cloud registration.
module "workload-identity" {
  source = "../modules/workload-identity/"

  wif_project_id            = var.wif_project_id
  wif_pool_id               = terraform_data.gws_registration.input.wif_pool_id
  wif_pool_provider_id      = terraform_data.gws_registration.input.wif_provider_id
  registration_id           = terraform_data.gws_registration.input.id
  identity_source           = local.identity_source
  role_arn                  = var.workspace_role_arn
  service_account_unique_id = var.workspace_service_account_unique_id
  resource_prefix           = local.effective_prefix
  resource_suffix           = local.effective_suffix
}

module "workspace" {
  source = "../modules/workspace/"

  wif_project_id            = var.wif_project_id
  service_account_id        = terraform_data.gws_registration.input.service_account_id
  workspace_wif_principal   = module.workload-identity.wif_iam_principal
  organization_id           = var.organization_id
  grant_organization_viewer = var.grant_organization_viewer
}
