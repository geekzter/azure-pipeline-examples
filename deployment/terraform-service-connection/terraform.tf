terraform {
  required_providers {
    azurerm                    = "~> 2.0"
  }
  required_version             = "~> 1.0"
}

provider azurerm {
   features {}
}