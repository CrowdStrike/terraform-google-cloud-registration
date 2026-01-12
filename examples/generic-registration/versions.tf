terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    crowdstrike = {
      source  = "crowdstrike/crowdstrike"
      version = "~> 0.0.55"
    }
  }
}
