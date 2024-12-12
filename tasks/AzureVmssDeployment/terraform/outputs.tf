output resource_group_is {    
  value                        = azurerm_resource_group.rg.id
}
output resource_group_name {    
  value                        = azurerm_resource_group.rg.name
}

output storage_account_id {
  value                        = azurerm_storage_account.script_storage.id
}
output storage_account_name {
  value                        = azurerm_storage_account.script_storage.name
}

output vmss_id {
  value                        = azurerm_linux_virtual_machine_scale_set.linux_agents.id
}
output vmss_name {
  value                        = azurerm_linux_virtual_machine_scale_set.linux_agents.name
}