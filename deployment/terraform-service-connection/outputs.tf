output client_id {
  value = data.azurerm_client_config.current.client_id
}

output subscription_id {
  value = data.azurerm_client_config.current.subscription_id
}

output networks {
  value = data.azurerm_resources.networks
}

output tenant_id {
  value = data.azurerm_client_config.current.tenant_id
}