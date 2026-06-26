# Azure Service Definitions

Per-service metadata for common Azure services. Each entry holds the
OAuth resource `host` (used to derive the `/.default` scope) and any
additional data-plane endpoints where requests are sent. For most
services the data-plane host is the same as the OAuth resource host;
Azure Storage is the exception (resource host `storage.azure.com`,
data-plane host `*.dfs.core.windows.net`).

## Usage

``` r
azure_services
```

## Format

An object of class `list` of length 10.
