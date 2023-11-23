variables {
  wait_time_minutes            = 15
}

run access_azurerm_subscription_1 {
  command                      = plan

  assert {
    condition                  = data.azurerm_subscription.current.display_name != null
    error_message              = "Subscription access failed"
  }
}

run wait {
  module {
    source                     = "./modules/timer"
  }
  variables {
    create_wait_minutes        = var.wait_time_minutes
  }
}
