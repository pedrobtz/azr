# Device code credential authentication

Authenticates a user through the device code flow. This flow is designed
for devices that don't have a web browser or have input constraints.

## Details

The device code flow displays a code that the user must enter on another
device with a web browser to complete authentication. This is ideal for
CLI applications, headless servers, or devices without a browser.

The credential supports token caching to avoid repeated authentication.
Tokens can be cached to disk or in memory.

## Super classes

`Credential` -\>
[`InteractiveCredential`](https://pedrobtz.github.io/azr/dev/reference/InteractiveCredential.md)
-\> `DeviceCodeCredential`

## Methods

### Public methods

- [`DeviceCodeCredential$new()`](#method-DeviceCodeCredential-initialize)

- [`DeviceCodeCredential$clone()`](#method-DeviceCodeCredential-clone)

Inherited methods

- `Credential$print()`
- `Credential$validate()`
- [`InteractiveCredential$get_token()`](https://pedrobtz.github.io/azr/dev/reference/InteractiveCredential.html#method-get_token)
- [`InteractiveCredential$is_interactive()`](https://pedrobtz.github.io/azr/dev/reference/InteractiveCredential.html#method-is_interactive)
- [`InteractiveCredential$req_auth()`](https://pedrobtz.github.io/azr/dev/reference/InteractiveCredential.html#method-req_auth)

------------------------------------------------------------------------

### `DeviceCodeCredential$new()`

Create a new device code credential

#### Usage

    DeviceCodeCredential$new(
      scope = NULL,
      tenant_id = NULL,
      client_id = default_azure_cli_client_id(),
      use_cache = "disk",
      offline = TRUE,
      allow_prompt = TRUE,
      use_refresh_token = TRUE,
      interactive = NULL
    )

#### Arguments

- `scope`:

  A character string specifying the OAuth2 scope. Defaults to `NULL`.

- `tenant_id`:

  A character string specifying the Azure Active Directory tenant ID.
  Defaults to `NULL`.

- `client_id`:

  A character string specifying the application (client) ID. Defaults to
  the Azure CLI public client ID.

- `use_cache`:

  A character string specifying the cache type. Use `"disk"` for
  disk-based caching or `"memory"` for in-memory caching. Defaults to
  `"disk"`.

- `offline`:

  A logical value indicating whether to request offline access (refresh
  tokens). Defaults to `TRUE`.

- `allow_prompt`:

  A logical value indicating whether this credential may prompt the user
  (vs. only reading cached/refresh tokens). Defaults to `TRUE`.

- `use_refresh_token`:

  A logical value indicating whether to use the login flow (acquire
  tokens via refresh token exchange). Defaults to `TRUE`.

- `interactive`:

  Deprecated. Use `allow_prompt` instead.

#### Returns

A new `DeviceCodeCredential` object

------------------------------------------------------------------------

### `DeviceCodeCredential$clone()`

The objects of this class are cloneable with this method.

#### Usage

    DeviceCodeCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# DeviceCodeCredential requires an interactive session
if (FALSE) { # \dontrun{
# Create credential with default settings
cred <- DeviceCodeCredential$new()

# Get an access token (will prompt for 'device code' flow)
token <- cred$get_token()

# Force re-authentication
token <- cred$get_token(reauth = TRUE)

# Use with httr2 request
req <- httr2::request("https://management.azure.com/subscriptions")
req <- cred$req_auth(req)
} # }
```
