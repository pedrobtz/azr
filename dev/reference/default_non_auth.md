# Default No Authentication

A pass-through credential function that performs no authentication. This
function returns the request object unchanged, allowing API calls to be
made without adding any authentication headers or tokens.

## Usage

``` r
default_non_auth(req)
```

## Arguments

- req:

  An
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object

## Value

The same
[`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
object, unmodified
