variable location {
  default                      = "centralus"
}

variable resource_prefix {
  default                      = "tf"
}
variable resource_suffix {
  description                  = "The suffix to put at the of resource names created"
  default                      = "" # Empty string triggers a random suffix
}

variable ssh_public_key {
  default                      = "~/.ssh/id_rsa.pub"
}

variable user_name {
  default = "azureuser"
  type = string
}

variable subnet_id {
  type = string
}
