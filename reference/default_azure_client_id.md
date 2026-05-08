# Get default Azure client ID

Retrieves the Azure client ID in priority order:

1.  `AZURE_CLIENT_ID` environment variable

2.  Built-in fallback (Microsoft's public Azure CLI client ID)

## Usage

``` r
default_azure_client_id()
```

## Value

A character string with the client ID

## Examples

``` r
default_azure_client_id()
#> [1] "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
```
