# Get an Access Token for the Signed-In User

Retrieves an authentication token for the person signed in on this
machine, skipping the service identities that
[`get_token()`](https://pedrobtz.github.io/azr/dev/reference/get_token.md)
would try first.

## Usage

``` r
get_user_token(
  scope = NULL,
  tenant_id = NULL,
  client_id = default_azure_cli_client_id(),
  use_cache = "disk",
  offline = TRUE
)
```

## Arguments

- scope:

  Optional character string specifying the authentication scope.

- tenant_id:

  Optional character string specifying the tenant ID for authentication.

- client_id:

  Optional character string specifying the client ID to authenticate
  against. Defaults to
  [`default_azure_cli_client_id()`](https://pedrobtz.github.io/azr/dev/reference/default_azure_cli_client_id.md),
  the public Azure CLI client, rather than to `AZURE_CLIENT_ID`: on a
  host configured for a service identity that variable holds the
  *workload's* application, which is not the application a person signs
  in to.

- use_cache:

  Character string indicating the caching strategy. Defaults to
  `"disk"`. Options include `"disk"` for disk-based caching or
  `"memory"` for in-memory caching.

- offline:

  Logical. If `TRUE`, adds 'offline_access' to the scope to request a
  'refresh_token'. Defaults to `TRUE`.

## Value

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object.

## Details

[`get_token()`](https://pedrobtz.github.io/azr/dev/reference/get_token.md)
walks the whole
[`default_credential_chain()`](https://pedrobtz.github.io/azr/dev/reference/default_credential_chain.md),
where `workload_identity` and `managed_identity` come before
`azure_cli`. On a host configured for a service identity - an AKS pod
setting `AZURE_FEDERATED_TOKEN_FILE`, a CI runner with OIDC - that means
[`get_token()`](https://pedrobtz.github.io/azr/dev/reference/get_token.md)
hands back the *workload's* identity even when a person is sitting at
the console. `get_user_token()` restricts the chain to the credentials
that represent a person, tried in the same order the default chain uses
them:

1.  Azure CLI Credential - the current `az login` session

2.  Authorization Code Credential - interactive browser sign-in

3.  Device Code Credential - interactive device code flow

The two interactive flows are skipped in non-interactive sessions, so on
an unattended host this resolves to the Azure CLI login or fails.
`client_secret` is deliberately absent from the arguments: it
authenticates an application, not a user.

## See also

[`get_token()`](https://pedrobtz.github.io/azr/dev/reference/get_token.md),
[`az_cli_get_token()`](https://pedrobtz.github.io/azr/dev/reference/az_cli_get_token.md),
[`default_credential_chain()`](https://pedrobtz.github.io/azr/dev/reference/default_credential_chain.md)

## Examples

``` r
if (FALSE) { # \dontrun{
scope <- "https://management.azure.com/.default"

# on a host configured for workload identity, this is the workload
get_token(scope = scope)

# ...while this is whoever ran `az login`
get_user_token(scope = scope)
} # }
```
