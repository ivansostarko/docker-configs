# Local state (demo). For real teams, migrate to a remote backend.
terraform {
  backend "local" {
    path = "state/terraform.tfstate"
  }
}
