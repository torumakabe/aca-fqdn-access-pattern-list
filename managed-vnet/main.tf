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

// TODO: This will be replaced with AzureRM provider once it supports ACA
resource "azapi_resource" "aca_env" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  name      = "ca-env-aca-poc"
  parent_id = azurerm_resource_group.aca_poc.id
  location  = azurerm_resource_group.aca_poc.location

  body = jsonencode({
    properties = {
      // ZoneRedundant must be disabled if InfrastructureSubnetId is not provided.
      zoneRedundant = false
      vnetConfiguration = {
        internal = false
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
    command = "sleep 300"
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
