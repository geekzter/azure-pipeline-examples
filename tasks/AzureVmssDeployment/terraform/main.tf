resource random_string suffix {
  length                       = 4
  upper                        = false
  lower                        = true
  numeric                      = false
  special                      = false
}

locals {
  suffix                       = var.resource_suffix != "" ? lower(var.resource_suffix) : random_string.suffix.result
}

resource azurerm_resource_group rg {
  name                         = terraform.workspace == "default" ? "${var.resource_prefix}-vmss-${local.suffix}" : "${var.resource_prefix}-${terraform.workspace}-vmss-${local.suffix}"
  location                     = var.location
}

resource azurerm_linux_virtual_machine_scale_set linux_agents {
  name                         = "${azurerm_resource_group.rg.name}-vmss"
  computer_name_prefix         = "linuxvmss"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name

  admin_username               = var.user_name
  instances                    = 2
  sku                          = "Standard_B2s"

  admin_ssh_key {
    username                   = var.user_name
    public_key                 = file(var.ssh_public_key)
  }

  identity {
    type                       = "SystemAssigned"
  }

  network_interface {
    name                       = "${azurerm_resource_group.rg.name}-vmss-nic"
    primary                    = true

    ip_configuration {
      name                     = "ipconfig"
      primary                  = true
      subnet_id                = var.subnet_id
    }
  }

  os_disk {
    storage_account_type       = "Standard_LRS"
    caching                    = "ReadWrite"
  }

  source_image_reference {
    publisher                  = "Canonical"
    offer                      = "0001-com-ubuntu-server-jammy"
    sku                        = "22_04-lts"
    version                    = "latest"
  }

  lifecycle {
    ignore_changes             = [
      extension,
      instances
    ]
  }

  tags                         = azurerm_resource_group.rg.tags
}

resource azurerm_storage_account script_storage {
  name                         = "${substr(lower(replace(azurerm_resource_group.rg.name,"/a|e|i|o|u|y|-/","")),0,15)}${substr(local.suffix,-6,-1)}src"
  location                     = var.location
  resource_group_name          = azurerm_resource_group.rg.name
  account_kind                 = "StorageV2"
  account_tier                 = "Standard"
  account_replication_type     = "LRS"
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  https_traffic_only_enabled   = true
  shared_access_key_enabled    = false

  tags                         = azurerm_resource_group.rg.tags
}