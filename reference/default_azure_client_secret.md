# Get default Azure client secret

Retrieves the Azure client secret from the `AZURE_CLIENT_SECRET`
environment variable, or returns `NA_character_` if not set.

## Usage

``` r
default_azure_client_secret()
```

## Value

A character string with the client secret, or `NA_character_` if not set

## Examples

``` r
default_azure_client_secret()
#> NULL
```
