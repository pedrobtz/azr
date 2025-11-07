# Get Default Request Authorizer Function

Creates a request authorizer function that retrieves authentication
credentials and returns a callable request authorization method. This
function handles the credential discovery process and returns the
request authentication method from the discovered credential object.

## Usage

``` r
get_request_authorizer(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = FALSE,
  .chain = default_credential_chain(),
  .silent = TRUE
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

  Logical. If `TRUE`, operates in offline mode. Defaults to `FALSE`.

- .chain:

  A list of credential objects, where each element must inherit from the
  `Credential` base class. Credentials are attempted in the order
  provided until `get_token` succeeds.

- .silent:

  Logical. If `FALSE`, prints detailed diagnostic information during
  credential discovery and authentication. Defaults to `TRUE`.

## Value

A function that authorizes HTTP requests with appropriate credentials
when called.

## See also

[`get_token_provider()`](https://pedrobtz.github.io/azr/reference/get_token_provider.md),
[`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

## Examples

``` r
# In non-interactive sessions, this function will return an error if the
# environment is not setup with valid credentials. And in an interactive session
# the user will be prompted to attempt one of the interactive authentication flows.
if (FALSE) { # \dontrun{
req_auth <- get_request_authorizer(
  scope = "https://graph.microsoft.com/.default"
)
req <- req_auth(httr2::request("https://graph.microsoft.com/v1.0/me"))
} # }
```
