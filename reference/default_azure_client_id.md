# Get default Azure client ID

Retrieves the Azure client ID from the `AZURE_CLIENT_ID` environment
variable, or falls back to the default Azure CLI client ID if not set.

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
