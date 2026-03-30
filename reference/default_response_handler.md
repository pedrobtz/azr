# Default response handler

Converts `data.frame` results in the parsed response to `data.table`
objects when the `data.table` package is available. Applied
automatically by
[api_client](https://pedrobtz.github.io/azr/reference/api_client.md)
unless overridden via the `response_handler` argument.

## Usage

``` r
default_response_handler(content)
```

## Arguments

- content:

  Parsed response content from an API call.

## Value

The processed content, with any `data.frame` objects converted to
`data.table` if the `data.table` package is installed.
