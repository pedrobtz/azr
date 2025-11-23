# Check if User is Logged in to Azure CLI

Checks whether the user is currently logged in to Azure CLI by
attempting to retrieve account information.

## Usage

``` r
az_cli_is_login(timeout = 10L)
```

## Arguments

- timeout:

  A numeric value specifying the timeout in seconds for the Azure CLI
  command. Defaults to `10`.

## Value

A logical value: `TRUE` if the user is logged in, `FALSE` otherwise

## Examples

``` r
if (FALSE) { # \dontrun{
# Check if logged in
if (az_cli_is_login()) {
  message("User is logged in")
} else {
  message("User is not logged in")
}
} # }
```
