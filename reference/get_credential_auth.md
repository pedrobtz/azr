# Get Credential Authentication Function

Creates a function that retrieves authentication tokens and formats them
as HTTP Authorization headers. This function handles credential
discovery and returns a callable method that generates Bearer token
headers when invoked.

## Usage

``` r
get_credential_auth(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  chain = default_credential_chain()
)
```

## Arguments

- scope:

  Optional character string specifying the authentication scope.

- tenant_id:

  Optional character string specifying the tenant ID for authentication.

- client_id:

  Optional character string specifying the client ID for authentication.

- client_secret:

  Optional character string specifying the client secret for
  authentication.

- use_cache:

  Character string indicating the caching strategy. Defaults to
  `"disk"`. Options include `"disk"` for disk-based caching or
  `"memory"` for in-memory caching.

- offline:

  Logical. If `TRUE`, adds 'offline_access' to the scope to request a
  'refresh_token'. Defaults to `TRUE`.

- chain:

  A list of credential objects, where each element must inherit from the
  `Credential` base class. Credentials are attempted in the order
  provided until `get_token` succeeds.

## Value

A function that, when called, returns a named list with an
`Authorization` element containing the Bearer token, suitable for use
with
[`httr2::req_headers()`](https://httr2.r-lib.org/reference/req_headers.html).

## See also

[`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md),
[`get_request_authorizer()`](https://pedrobtz.github.io/azr/reference/get_request_authorizer.md),
[`get_token_provider()`](https://pedrobtz.github.io/azr/reference/get_token_provider.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Create an authentication function
auth_fn <- get_credential_auth(
  scope = "https://graph.microsoft.com/.default"
)

# Call it to get headers
auth_headers <- auth_fn()

# Use with httr2
req <- httr2::request("https://graph.microsoft.com/v1.0/me") |>
  httr2::req_headers(!!!auth_headers)
} # }
```
