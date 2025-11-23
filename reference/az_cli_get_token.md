# Get Access Token from Azure CLI

Retrieves an access token from Azure CLI using the
`az account get-access-token` command. This is a lower-level function
that directly interacts with the Azure CLI to obtain OAuth2 tokens.

## Usage

``` r
az_cli_get_token(scope, tenant_id = NULL, timeout = 10L)
```

## Arguments

- scope:

  A character string specifying the OAuth2 scope for which to request
  the access token (e.g., `"https://management.azure.com/.default"`).

- tenant_id:

  A character string specifying the Azure Active Directory tenant ID. If
  `NULL`, uses the default tenant from Azure CLI. Defaults to `NULL`.

- timeout:

  A numeric value specifying the timeout in seconds for the Azure CLI
  process. Defaults to `10`.

## Value

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing:

- `access_token`: The OAuth2 access token string

- `token_type`: The type of token (typically "Bearer")

- `.expires_at`: POSIXct timestamp when the token expires

## Details

This function executes the Azure CLI command and parses the JSON
response to create an httr2 OAuth token object. The token includes the
access token, token type, and expiration time.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get a token for Azure Resource Manager
token <- az_cli_get_token(
  scope = "https://management.azure.com/.default"
)

# Get a token for a specific tenant
token <- az_cli_get_token(
  scope = "https://graph.microsoft.com/.default",
  tenant_id = "your-tenant-id"
)

# Access the token string
access_token <- token$access_token
} # }
```
