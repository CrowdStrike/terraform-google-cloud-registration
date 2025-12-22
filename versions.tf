terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source                = "hashicorp/google"
      version               = "~> 5.0"
      configuration_aliases = [google.wif]
    }
    crowdstrike = {
      source  = "crowdstrike/crowdstrike"
      version = "~> 0.0.53"
    }
  }
}
