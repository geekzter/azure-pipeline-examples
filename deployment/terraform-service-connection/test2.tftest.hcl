run access_azurerm_subscription_1 {
  command                      = plan

  assert {
    condition                  = data.azurerm_subscription.current.display_name != null
    error_message              = "Subscription access failed"
  }
}