# Get default federated token file path

Retrieves the path to the federated identity token file from the
`AZURE_FEDERATED_TOKEN_FILE` environment variable, or returns `NULL` if
not set. Used by
[WorkloadIdentityCredential](https://pedrobtz.github.io/azr/reference/WorkloadIdentityCredential.md).

## Usage

``` r
default_federated_token_file()
```

## Value

A character string with the file path, or `NULL` if not set

## Examples

``` r
default_federated_token_file()
#> NULL
```
