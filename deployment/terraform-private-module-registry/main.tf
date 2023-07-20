module hello_module {
  # Literal expression, no variables allowed
  # source = "./modules/module"
  source = "git::https://dev.azure.com/ericvan/PipelineSamples/_git/terraform-modules-sample//modules/module?ref=main"
}

