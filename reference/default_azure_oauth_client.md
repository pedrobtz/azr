# Create default Azure OAuth client

Creates an
[`httr2::oauth_client()`](https://httr2.r-lib.org/reference/oauth_client.html)
configured for Azure authentication.

## Usage

``` r
default_azure_oauth_client(
  client_id = default_azure_client_id(),
  client_secret = NULL,
  name = NULL
)
```

## Arguments

- client_id:

  A character string specifying the client ID. Defaults to
  [`default_azure_client_id()`](https://pedrobtz.github.io/azr/reference/default_azure_client_id.md).

- client_secret:

  A character string specifying the client secret. Defaults to `NULL`.

- name:

  A character string specifying the client name. Defaults to `NULL`.

## Value

An
[`httr2::oauth_client()`](https://httr2.r-lib.org/reference/oauth_client.html)
object

## Examples

``` r
client <- default_azure_oauth_client()
client <- default_azure_oauth_client(
  client_id = "my-client-id",
  client_secret = "my-secret"
)
```
