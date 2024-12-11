terraform {
  required_providers {
    azurerm                    = "~> 4.13"
    random                     = "~> 3.6"
  }
  required_version             = "~> 1.0"
}

# Microsoft Azure Resource Manager Provider
provider azurerm {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine_scale_set {
      roll_instances_when_required = true
    }
  }

  storage_use_azuread          = true
}
