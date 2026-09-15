terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 6.22"
    }
    crowdstrike = {
      # TEMPORARY: pinned to the dev build with existing_wif_pool_id support.
      source  = "cs-dev-cloudconnect-templates.s3.us-east-1.amazonaws.com/crowdstrike-dev/crowdstrike"
      version = "0.0.88-2faea99"
    }
  }
}
