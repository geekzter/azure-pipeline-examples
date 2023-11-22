provider azurerm {
  alias                        = "a"
  features {}
}
run access_azurerm_subscription_1 {
  command                      = plan

  providers                    = {
    azurerm                    = azurerm.a
  }
  
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
    create_wait_minutes        = 15
  }
}

// provider azurerm {
//   alias                        = "b"
// //   features {
// //     resource_group {
// //       prevent_deletion_if_contains_resources = run.wait.dummy
// //     }
// //   }
// }

// run access_azurerm_subscription_2 {
//   command                      = plan

//   providers                    = {
//     azurerm                    = azurerm.b
//   }
  
//   assert {
//     condition                  = data.azurerm_subscription.current.display_name != null
//     error_message              = "Subscription access failed"
//   }
// }