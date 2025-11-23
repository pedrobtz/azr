# Default Response Handler

Default callback function for processing API response content. This
function converts data frames within lists to data.table objects for
better performance and functionality, if the data.table package is
available.

## Usage

``` r
default_response_handler()
```

## Value

A function that accepts parsed response content and returns processed
content

## Details

The function recursively processes list responses and converts any
data.frame objects to data.table objects using
[`data.table::as.data.table()`](https://rdatatable.gitlab.io/data.table/reference/as.data.table.html),
but only if the data.table package is installed. If data.table is not
available, data frames are returned unchanged. Non-data.frame elements
are always returned unchanged.

## Examples

``` r
# Get the default handler
handler <- default_response_handler()

# Use with a custom handler
custom_handler <- function(content) {
  # Your custom processing logic
  content
}
```
