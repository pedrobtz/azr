# Get default Azure authority host

Retrieves the Azure authority host from the `AZURE_AUTHORITY_HOST`
environment variable, or falls back to Azure Public Cloud if not set.

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
