output client_id {
  value = data.azurerm_client_config.current.client_id
}

output subscription_id {
  value = data.azurerm_client_config.current.subscription_id
}
output subscription_name {
  value = data.azurerm_subscription.current.display_name
}
output subscription_state {
  value = data.azurerm_subscription.current.state
}

output tenant_id {
  value = data.azurerm_client_config.current.tenant_id
}