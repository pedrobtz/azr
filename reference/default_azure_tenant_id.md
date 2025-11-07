# Get default Azure tenant ID

Retrieves the Azure tenant ID from the `AZURE_TENANT_ID` environment
variable, or falls back to the default value if not set.

## Usage

``` r
default_azure_tenant_id()
```

## Value

A character string with the tenant ID

## Examples

``` r
default_azure_tenant_id()
#> [1] "common"
```
