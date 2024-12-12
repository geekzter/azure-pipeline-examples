data azurerm_client_config default {}

locals {
  principal_id                 = coalesce(var.principal_id,data.azurerm_client_config.default.object_id)
}

resource azurerm_role_assignment azure_access {
  scope                        = azurerm_resource_group.rg.id
  role_definition_name         = "Contributor"
  principal_id                 = local.principal_id
}

resource azurerm_role_assignment storage_access {
  scope                        = azurerm_resource_group.rg.id
  role_definition_name         = "Storage Blob Data Contributor"
  principal_id                 = local.principal_id
}
