terraform {
  required_providers {
    azurerm                    = "~> 3.55"
  }
  required_version             = "~> 1.0"
}

provider azurerm {
   features {}
}