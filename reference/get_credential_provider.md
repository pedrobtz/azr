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
  offline = TRUE,
  oauth_host = NULL,
  oauth_endpoint = NULL,
  chain = NULL,
  allow_interactive = rlang::is_interactive(),
  verbose = opts$get("chain_verbose"),
  interactive = NULL
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

- oauth_host:

  Optional character string specifying the OAuth host URL.

- oauth_endpoint:

  Optional character string specifying the OAuth endpoint.

- chain:

  A list of credential objects, where each element must inherit from the
  `Credential` base class. Credentials are attempted in the order
  provided until `get_token` succeeds. If `NULL`, uses
  [`default_credential_chain()`](https://pedrobtz.github.io/azr/reference/default_credential_chain.md).

- allow_interactive:

  A logical value indicating whether interactive credentials are
  allowed. Defaults to
  [`rlang::is_interactive()`](https://rlang.r-lib.org/reference/is_interactive.html).

- verbose:

  A logical value indicating whether to print verbose messages during
  credential discovery. Defaults to the `chain_verbose` option, which
  reads `options(azr.chain_verbose = ...)` or the `AZR_CHAIN_VERBOSE`
  environment variable; see
  [`azr_options()`](https://pedrobtz.github.io/azr/reference/azr_options.md).

- interactive:

  Deprecated. Use `allow_interactive` instead.

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
