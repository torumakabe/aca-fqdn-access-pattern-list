terraform {
  required_version = "~> 1.2.4"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.12.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 0.4.0"
    }
  }
}

module "aca_vnet_subnet_addrs" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = local.subnet_addrs.base_cidr_block
  networks = [
    {
      name     = "default"
      new_bits = 8
    },
    {
      name = "aca"
      // must have a size of at least /23
      new_bits = 7
    },
  ]
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

resource "azurerm_resource_group" "aca_poc" {
  name     = local.rg.name
  location = local.rg.location
}

resource "azurerm_virtual_network" "aca" {
  name                = "vnet-aca"
  resource_group_name = azurerm_resource_group.aca_poc.name
  location            = azurerm_resource_group.aca_poc.location
  address_space       = [module.aca_vnet_subnet_addrs.base_cidr_block]
}

resource "azurerm_subnet" "aca_default" {
  name                 = "snet-default"
  resource_group_name  = azurerm_resource_group.aca_poc.name
  virtual_network_name = azurerm_virtual_network.aca.name
  address_prefixes     = [module.aca_vnet_subnet_addrs.network_cidr_blocks["default"]]
}


resource "azurerm_subnet" "aca_aca" {
  // workaround: operate subnets one after another
  // https://github.com/hashicorp/terraform-provider-azurerm/issues/3780
  depends_on = [
    azurerm_subnet.aca_default
  ]
  name                 = "snet-aca"
  resource_group_name  = azurerm_resource_group.aca_poc.name
  virtual_network_name = azurerm_virtual_network.aca.name
  address_prefixes     = [module.aca_vnet_subnet_addrs.network_cidr_blocks["aca"]]
}

// TODO: This will be replaced with AzureRM provider once it supports ACA
resource "azapi_resource" "aca_env" {
  depends_on = [
    azurerm_subnet.aca_aca
  ]
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  name      = "ca-env-aca-poc"
  parent_id = azurerm_resource_group.aca_poc.id
  location  = azurerm_resource_group.aca_poc.location

  body = jsonencode({
    properties = {
      zoneRedundant = true
      vnetConfiguration = {
        internal               = false
        infrastructureSubnetId = azurerm_subnet.aca_aca.id
      }
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = var.log_analytics.workspace.id
          sharedKey  = var.log_analytics.workspace.key
        }
      }
    }
  })

  ignore_missing_property = true
  response_export_values  = ["properties.defaultDomain", "properties.staticIp"]

  // Workaroud: delete operation complete immediatelly but it's actually running asynchronously, so occur "InUseSubnetCannotBeDeleted" error
  // If you are in a hurry, it is faster to delete the resource group directly in the CLI or portal
  provisioner "local-exec" {
    when    = destroy
    command = "sleep 1800"
  }
}

// TODO: This will be replaced with AzureRM provider once it supports ACA
resource "azapi_resource" "aca_app_nginx_with_external_ingress" {
  depends_on = [
    azapi_resource.aca_env
  ]
  type      = "Microsoft.App/containerApps@2022-03-01"
  name      = "ca-app-aca-poc-nginx-ext-ing"
  parent_id = azurerm_resource_group.aca_poc.id
  location  = azurerm_resource_group.aca_poc.location
  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.aca_env.id
      configuration = {
        ingress = {
          targetPort = 80
          external   = true
        }
      },
      template = {
        containers = [
          {
            image = "nginx"
            name  = "nginx"
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
          }
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })

  ignore_missing_property = true
}

// TODO: This will be replaced with AzureRM provider once it supports ACA
resource "azapi_resource" "aca_app_nginx_with_internal_ingress" {
  depends_on = [
    azapi_resource.aca_env
  ]
  type      = "Microsoft.App/containerApps@2022-03-01"
  name      = "ca-app-aca-poc-nginx-int-ing"
  parent_id = azurerm_resource_group.aca_poc.id
  location  = azurerm_resource_group.aca_poc.location
  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.aca_env.id
      configuration = {
        ingress = {
          targetPort = 80
          external   = false
        }
      },
      template = {
        containers = [
          {
            image = "nginx"
            name  = "nginx"
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
          }
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })

  ignore_missing_property = true
}

// TODO: This will be replaced with AzureRM provider once it supports ACA
resource "azapi_resource" "aca_app_ubuntu" {
  depends_on = [
    azapi_resource.aca_env
  ]
  type      = "Microsoft.App/containerApps@2022-03-01"
  name      = "ca-app-aca-poc-ubuntu"
  parent_id = azurerm_resource_group.aca_poc.id
  location  = azurerm_resource_group.aca_poc.location
  identity {
    type = "SystemAssigned"
  }

  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.aca_env.id
      configuration = {
      },
      template = {
        containers = [
          {
            image = "ubuntu"
            name  = "ubuntu"
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
            command = ["tail"]
            args    = ["-f", "/dev/null"]
          }
        ]
        scale = {
          minReplicas = 1
          maxReplicas = 1
        }
      }
    }
  })

  ignore_missing_property = true
}

resource "azurerm_private_dns_zone" "aca_env" {
  name                = jsondecode(azapi_resource.aca_env.output).properties.defaultDomain
  resource_group_name = azurerm_resource_group.aca_poc.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "aca_env" {
  name                  = "pdnsz-link-aca-env"
  resource_group_name   = azurerm_resource_group.aca_poc.name
  private_dns_zone_name = azurerm_private_dns_zone.aca_env.name
  virtual_network_id    = azurerm_virtual_network.aca.id
  registration_enabled  = true
}

resource "azurerm_private_dns_a_record" "aca_env" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.aca_env.name
  resource_group_name = azurerm_resource_group.aca_poc.name
  ttl                 = 300
  records             = [jsondecode(azapi_resource.aca_env.output).properties.staticIp]
}

resource "azurerm_network_security_group" "default" {
  name                = "nsg-default"
  resource_group_name = azurerm_resource_group.aca_poc.name
  location            = azurerm_resource_group.aca_poc.location

  // Do not assign rules for SSH statically, use JIT
}

resource "azurerm_public_ip" "client_same_vnet" {
  name                = "pip-client-same-vnet"
  resource_group_name = azurerm_resource_group.aca_poc.name
  location            = azurerm_resource_group.aca_poc.location
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "client_same_vnet" {
  name                          = "nic-client-same-vnet"
  resource_group_name           = azurerm_resource_group.aca_poc.name
  location                      = azurerm_resource_group.aca_poc.location
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "default"
    subnet_id                     = azurerm_subnet.aca_default.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.client_same_vnet.id
  }
}

resource "azurerm_network_interface_security_group_association" "client_same_vnet" {
  network_interface_id      = azurerm_network_interface.client_same_vnet.id
  network_security_group_id = azurerm_network_security_group.default.id
}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "client_same_vnet" {
  name                            = "vm-client-same-vnet"
  resource_group_name             = azurerm_resource_group.aca_poc.name
  location                        = azurerm_resource_group.aca_poc.location
  size                            = "Standard_D2ds_v4"
  admin_username                  = var.admin_username
  disable_password_authentication = true
  identity {
    type = "SystemAssigned"
  }
  network_interface_ids = [
    azurerm_network_interface.client_same_vnet.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadOnly"
    storage_account_type = "Standard_LRS"
    diff_disk_settings {
      option = "Local"
    }
    disk_size_gb = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "aad_ssh_login_client_same_vnet" {
  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.client_same_vnet.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
}
