# Write an httr2 Token to the MSAL Token Cache

Writes an
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object into the MSAL token cache JSON file (`msal_token_cache.json`)
shared by the Azure SDK and Azure CLI. The resulting entry is readable
by other Azure tools (Python SDK, Azure CLI, and the rest of this
package via
[`az_cli_get_cached_token()`](https://pedrobtz.github.io/azr/reference/az_cli_get_cached_token.md)).

## Usage

``` r
write_msal_token(token, cache_file = default_msal_token_cache())
```

## Arguments

- token:

  An
  [`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
  object. Must contain `access_token`, `token_type`, and `.expires_at`.
  May optionally contain `refresh_token` and `scope`. All cache fields
  (`home_account_id`, `tenant_id`, `username`, `client_id`, `scope`,
  `environment`) are derived from the JWT claims (`oid`, `tid`,
  `upn`/`preferred_username`, `appid`/`azp`, `scp`/`scope`, `iss`) and
  the token object itself.

- cache_file:

  Path to the MSAL token cache JSON file. Defaults to
  [`default_msal_token_cache()`](https://pedrobtz.github.io/azr/reference/default_msal_token_cache.md).

## Value

Invisibly returns the path to the cache file.

## Details

The function adds or overwrites `AccessToken`, `RefreshToken` (when the
token carries a refresh token), `Account`, and `AppMetadata` sections.
Existing entries for other accounts or clients are preserved.

The `home_account_id` follows the MSAL convention
`"<object_id>.<tenant_id>"` where `object_id` is the Azure AD OID of the
authenticated principal. Cache entry keys are built in the same format
used by the Azure CLI and MSAL Python:

- AccessToken:
  `<home_account_id>-<environment>-accesstoken-<client_id>-<realm>-<target>`

- RefreshToken:
  `<home_account_id>-<environment>-refreshtoken-<client_id>--`

- Account: `<home_account_id>-<environment>-<realm>`

- AppMetadata: `appmetadata-<environment>-<client_id>`

## See also

[`az_cli_get_cached_token()`](https://pedrobtz.github.io/azr/reference/az_cli_get_cached_token.md),
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
