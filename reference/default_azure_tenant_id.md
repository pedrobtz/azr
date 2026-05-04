# Get default Azure tenant ID

Retrieves the Azure tenant ID in priority order:

1.  Package-level override set via
    [`set_azr_defaults()`](https://pedrobtz.github.io/azr/reference/set_azr_defaults.md)

2.  `AZURE_TENANT_ID` environment variable

3.  Built-in fallback (`"common"`)

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
