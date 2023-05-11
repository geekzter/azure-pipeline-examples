output client_id {
  value = data.azurerm_client_config.current.client_id
}

output subscription_id {
  value = data.azurerm_client_config.current.subscription_id
}

output tenant_id {
  value = data.azurerm_client_config.current.tenant_id
}