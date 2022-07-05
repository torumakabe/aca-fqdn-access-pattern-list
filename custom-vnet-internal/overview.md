# Custom VNet - Visibility "Internal"

## Overview

```mermaid
graph TB
    subgraph VNet-Custom
        subgraph ContainerApps-Env
            LB-Internal --> Ingress
            LB-External
            Ingress --> Rule-Target-FQDN
            Rule-Target-FQDN --> FQDN-External
            Rule-Target-FQDN --> FQDN-Internal
            FQDN-External --> External-True([Is Ingress External true?])
            FQDN-Internal --> From-Env([From the same Contaner Apps Env?])
            External-True --> App-with-Ingress
            From-Env --> App-with-Ingress
            App --> Ingress
            App --> DNS-ACA-Internal
            DNS-ACA-Internal
            Outbound([Outbound Traffic]) --> LB-External
        end
        Private-Link-Service --> LB-Internal
        Client-Private --> LB-Internal
    end
    subgraph VNet-Other
        Client-Private-Other --> Private-Endpoint
        Private-Endpoint --> Private-Link-Service
    end
    Client-Private --> DNS-Azure-Private
    Client-Private-Other --> DNS-Azure-Private-Other
    LB-External --> Internet((Internet))
```

## Access Pattern

| Ingress external | Source                 | Target FQDN                                                                 | Resolved Target IP                  |
|------------------|------------------------|-----------------------------------------------------------------------------|----------------------------|
| true             | Same Container App Env | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Container App Env Internal |
|                  |                        | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
|                  | Same VNet              | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Private (Same VNet)        |
|                  | Other Vnet             | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Private (Same/Other VNet)  |
| false            | Same Container App Env | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
