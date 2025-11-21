config {
  format = "compact"
}

plugin "google" {
  enabled = true
  version = "0.37.1"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}