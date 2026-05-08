# Get default Azure tenant ID

Retrieves the Azure tenant ID in priority order:

1.  `AZURE_TENANT_ID` environment variable

2.  Built-in fallback (`"common"`)

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
