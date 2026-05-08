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

`azr::Credential` -\>
[`azr::InteractiveCredential`](https://pedrobtz.github.io/azr/reference/InteractiveCredential.md)
-\> `DeviceCodeCredential`

## Methods

### Public methods

- [`DeviceCodeCredential$new()`](#method-DeviceCodeCredential-new)

- [`DeviceCodeCredential$clone()`](#method-DeviceCodeCredential-clone)

Inherited methods

- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)
- [`azr::Credential$validate()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-validate)
- [`azr::InteractiveCredential$get_token()`](https://pedrobtz.github.io/azr/reference/InteractiveCredential.html#method-get_token)
- [`azr::InteractiveCredential$is_interactive()`](https://pedrobtz.github.io/azr/reference/InteractiveCredential.html#method-is_interactive)
- [`azr::InteractiveCredential$req_auth()`](https://pedrobtz.github.io/azr/reference/InteractiveCredential.html#method-req_auth)

------------------------------------------------------------------------

### Method `new()`

Create a new device code credential

#### Usage

    DeviceCodeCredential$new(
      scope = NULL,
      tenant_id = NULL,
      client_id = default_azure_cli_client_id(),
      use_cache = "disk",
      offline = TRUE,
      interactive = TRUE,
      use_refresh_token = TRUE
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

- `interactive`:

  A logical value indicating whether this credential requires user
  interaction. Defaults to `TRUE`.

- `use_refresh_token`:

  A logical value indicating whether to use the login flow (acquire
  tokens via refresh token exchange). Defaults to `TRUE`.

#### Returns

A new `DeviceCodeCredential` object

------------------------------------------------------------------------

### Method `clone()`

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
