# Get default OAuth redirect URI

Constructs a redirect URI for OAuth flows. If the provided URI doesn't
have a port, assigns a random port using
[`httpuv::randomPort()`](https://rdrr.io/pkg/httpuv/man/randomPort.html).

## Usage

``` r
default_redirect_uri(redirect_uri = httr2::oauth_redirect_uri())
```

## Arguments

- redirect_uri:

  A character string specifying the redirect URI. Defaults to
  [`httr2::oauth_redirect_uri()`](https://httr2.r-lib.org/reference/oauth_redirect_uri.html).

## Value

A character string with the redirect URI

## Examples

``` r
default_redirect_uri()
#> [1] "http://localhost:35782/"
```
