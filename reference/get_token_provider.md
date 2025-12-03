# Get Default Token Provider Function

Creates a token provider function that retrieves authentication
credentials and returns a callable token getter. This function handles
the credential discovery process and returns the token acquisition
method from the discovered credential object.

## Usage

``` r
get_token_provider(
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

A function that retrieves and returns an authentication token when
called.

## See also

[`get_request_authorizer()`](https://pedrobtz.github.io/azr/reference/get_request_authorizer.md),
[`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

## Examples

``` r
# In non-interactive sessions, this function will return an error if the
# environment is not set up with valid credentials. In an interactive session
# the user will be prompted to attempt one of the interactive authentication flows.
if (FALSE) { # \dontrun{
token_provider <- get_token_provider(
  scope = "https://graph.microsoft.com/.default",
  tenant_id = "my-tenant-id",
  client_id = "my-client-id",
  client_secret = "my-secret"
)
token <- token_provider()
} # }
```
