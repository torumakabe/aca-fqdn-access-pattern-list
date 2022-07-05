# Custom VNet - Visibility "External"

## Overview

```mermaid
graph TB
    subgraph VNet-Custom
        subgraph ContainerApps-Env
            LB-External --> Ingress
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
        end
        Client-Private
    end
    Client-Private --> DNS-Azure-Private
    Client-Private --> Public-IP
    Public-IP --> LB-External
    Client-Public --> Public-IP
    Client-Public --> DNS-Azure-Public
```

## Access Pattern

| Ingress external | Source                 | Target FQDN                                                                 | Resolved Target IP                  |
|------------------|------------------------|-----------------------------------------------------------------------------|----------------------------|
| true             | Same Container App Env | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Container App Env Internal |
|                  |                        | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
|                  | Same VNet              | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Public                     |
|                  | Public                 | <APP_NAME>.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io          | Public                     |
| false            | Same Container App Env | <APP_NAME>.internal.<UNIQUE_IDENTIFIER>.<REGION_NAME>.azurecontainerapps.io | Container App Env Internal |
