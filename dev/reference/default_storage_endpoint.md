# Get default Azure Storage DFS endpoint suffix

Returns the default endpoint suffix used to construct Azure Data Lake
Storage Gen2 DFS URLs.

## Usage

``` r
default_storage_endpoint()
```

## Value

A character string with the DFS endpoint suffix.

## Examples

``` r
default_storage_endpoint()
#> [1] "dfs.core.windows.net"
```
