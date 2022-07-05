# FQDN Access Pattern list of Azure Container Apps

* [Managed VNet](./managed-vnet/overview.md)
* Custom VNet
  * Visibility Level
    * [External](./custom-vnet-external/overview.md)
    * [Internal](./custom-vnet-internal/overview.md)

## Access Pattern (All)

| VNet    | Accessibility Level | Ingress external | Source                 | Target FQDN                                                                 | Resolved Target IP         |
|---------|---------------------|------------------|------------------------|-----------------------------------------------------------------------------|----------------------------|
| Managed | External(Only)      | true             | Same Container App Env | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Container App Env Internal |
|         |                     |                  |                        | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
|         |                     |                  | Public                 | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Public                     |
|         |                     | false            | Same Container App Env | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
| Custom  | External            | true             | Same Container App Env | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Container App Env Internal |
|         |                     |                  |                        | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
|         |                     |                  | Same VNet              | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Public                     |
|         |                     |                  | Public                 | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Public                     |
|         |                     | false            | Same Container App Env | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
|         | Internal            | true             | Same Container App Env | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Container App Env Internal |
|         |                     |                  |                        | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
|         |                     |                  | Same VNet              | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Private (Same VNet)        |
|         |                     |                  | Other Vnet             | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Private (Same/Other VNet)  |
|         |                     | false            | Same Container App Env | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
