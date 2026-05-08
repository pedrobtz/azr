# Get default Azure authority host

Retrieves the Azure authority host in priority order:

1.  `AZURE_AUTHORITY_HOST` environment variable

2.  Built-in fallback (`login.microsoftonline.com`)

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
