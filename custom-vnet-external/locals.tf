locals {
  subnet_addrs = {
    base_cidr_block = "192.168.0.0/16"
  }
  rg = {
    name     = "rg-aca-poc"
    location = "japaneast"
  }
}

data "azurerm_client_config" "current" {}
