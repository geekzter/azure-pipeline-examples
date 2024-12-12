variable location {
  default                      = "centralus"
  type                         = string
}

variable principal_id {
  default                      = null
  type                         = string
}

variable resource_prefix {
  default                      = "tf"
  type                         = string
}
variable resource_suffix {
  description                  = "The suffix to put at the of resource names created"
  default                      = "" # Empty string triggers a random suffix
}

variable ssh_public_key {
  default                      = "~/.ssh/id_rsa.pub"
  type                         = string
}
variable user_name {
  default                      = "azureuser"
  type                         = string
}

variable subnet_id {
  type                         = string
}
