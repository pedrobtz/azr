# Get default Azure authority host

Retrieves the Azure authority host in priority order:

1.  Package-level override set via
    [`set_azr_defaults()`](https://pedrobtz.github.io/azr/reference/set_azr_defaults.md)

2.  `AZURE_AUTHORITY_HOST` environment variable

3.  Built-in fallback (`login.microsoftonline.com`)

## Usage

``` r
default_azure_host()
```

## Value

A character string with the authority host URL

## Examples

``` r
default_azure_host()
#> [1] "login.microsoftonline.com"
```
