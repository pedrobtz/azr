# Get default Azure Log Analytics query endpoint

Returns the default host used to construct Azure Log Analytics query
URLs (`api.loganalytics.io`).

## Usage

``` r
default_log_analytics_endpoint()
```

## Value

A character string with the Log Analytics query endpoint host.

## Examples

``` r
default_log_analytics_endpoint()
#> [1] "api.loganalytics.io"
```
