# Get Cached Token from MSAL Token Cache

Reads the MSAL token cache file (`msal_token_cache.json`) from the Azure
configuration directory and returns a matching access token as an
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object.

## Usage

``` r
az_cli_get_cached_token(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  config_dir = default_azure_config_dir()
)
```

## Arguments

- scope:

  A character string specifying the OAuth2 scope to filter tokens. If
  `NULL` (default), returns the latest-expiring token regardless of
  scope.

- tenant_id:

  A character string specifying the tenant ID to filter tokens. If
  `NULL` (default), matches any tenant.

- client_id:

  A character string specifying the client ID to filter tokens. If
  `NULL` (default), matches any client.

- config_dir:

  A character string specifying the Azure configuration directory.
  Defaults to
  [`default_azure_config_dir()`](https://pedrobtz.github.io/azr/reference/default_azure_config_dir.md).

## Value

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing:

- `access_token`: The OAuth2 access token string

- `token_type`: The type of token (typically "Bearer")

- `.expires_at`: POSIXct timestamp when the token expires

## Details

The MSAL token cache is a JSON file maintained by the Azure CLI that
stores access tokens and refresh tokens. This function reads cached
access tokens directly from the file without invoking the Azure CLI,
which can be useful in environments where the CLI is slow or unavailable
but tokens have been previously cached.

When multiple tokens are found, the function selects the token that
expires latest. If `scope` is provided, only tokens matching that
scope/resource are returned.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get any cached token
token <- az_cli_get_cached_token()

# Get a cached token for a specific scope
token <- az_cli_get_cached_token(
  scope = "https://management.azure.com/.default"
)

# Access the token string
token$access_token
} # }
```
