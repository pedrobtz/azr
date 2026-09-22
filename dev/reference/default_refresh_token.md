# Get default Azure refresh token

Retrieves the Azure refresh token from the `AZURE_REFRESH_TOKEN`
environment variable, or returns `NULL` if not set.

## Usage

``` r
default_refresh_token()
```

## Value

A character string with the refresh token, or `NULL` if not set

## Examples

``` r
default_refresh_token()
#> NULL
```
