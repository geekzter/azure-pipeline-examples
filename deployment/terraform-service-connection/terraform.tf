terraform {
  required_providers {
    azurerm                    = "~> 3.55"
  }
  required_version             = "~> 1.0"
}

provider azurerm {
  use_cli                      = false
  use_oidc                     = true
  features {}
}