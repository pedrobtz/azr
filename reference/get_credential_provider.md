# Get Credential Provider

Discovers and returns an authenticated credential object from a chain of
credential providers. This function attempts each credential in the
chain until one successfully authenticates, returning the first
successful credential object.

## Usage

``` r
get_credential_provider(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = FALSE,
  oauth_host = NULL,
  oauth_endpoint = NULL,
  .chain = NULL
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
  'refresh_token'. Defaults to `FALSE`.

- oauth_host:

  Optional character string specifying the OAuth host URL.

- oauth_endpoint:

  Optional character string specifying the OAuth endpoint.

- .chain:

  A list of credential objects, where each element must inherit from the
  `Credential` base class. Credentials are attempted in the order
  provided until `get_token` succeeds. If `NULL`, uses
  [`default_credential_chain()`](https://pedrobtz.github.io/azr/reference/default_credential_chain.md).

## Value

A credential object that inherits from the `Credential` class and has
successfully authenticated.

## See also

[`get_token_provider()`](https://pedrobtz.github.io/azr/reference/get_token_provider.md),
[`get_request_authorizer()`](https://pedrobtz.github.io/azr/reference/get_request_authorizer.md),
[`default_credential_chain()`](https://pedrobtz.github.io/azr/reference/default_credential_chain.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get a credential provider with default settings
cred <- get_credential_provider(
  scope = "https://graph.microsoft.com/.default",
  tenant_id = "my-tenant-id"
)

# Use the credential to get a token
token <- cred$get_token()
} # }
```
