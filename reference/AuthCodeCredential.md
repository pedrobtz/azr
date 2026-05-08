# Authorization code credential authentication

Authenticates a user through the OAuth 2.0 authorization code flow. This
flow opens a web browser for the user to sign in.

## Details

The authorization code flow is the standard OAuth 2.0 flow for
interactive authentication. It requires a web browser and is suitable
for applications where the user can interact with a browser window.

The credential supports token caching to avoid repeated authentication.
Tokens can be cached to disk or in memory. A redirect URI is required
for the OAuth flow to complete.

## Super classes

`azr::Credential` -\>
[`azr::InteractiveCredential`](https://pedrobtz.github.io/azr/reference/InteractiveCredential.md)
-\> `AuthCodeCredential`

## Methods

### Public methods

- [`AuthCodeCredential$new()`](#method-AuthCodeCredential-new)

- [`AuthCodeCredential$clone()`](#method-AuthCodeCredential-clone)

Inherited methods

- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)
- [`azr::Credential$validate()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-validate)
- [`azr::InteractiveCredential$get_token()`](https://pedrobtz.github.io/azr/reference/InteractiveCredential.html#method-get_token)
- [`azr::InteractiveCredential$is_interactive()`](https://pedrobtz.github.io/azr/reference/InteractiveCredential.html#method-is_interactive)
- [`azr::InteractiveCredential$req_auth()`](https://pedrobtz.github.io/azr/reference/InteractiveCredential.html#method-req_auth)

------------------------------------------------------------------------

### Method `new()`

Create a new authorization code credential

#### Usage

    AuthCodeCredential$new(
      scope = NULL,
      tenant_id = NULL,
      client_id = default_azure_cli_client_id(),
      use_cache = "disk",
      offline = TRUE,
      redirect_uri = default_redirect_uri(),
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

- `redirect_uri`:

  A character string specifying the redirect URI registered with the
  application. Defaults to
  [`default_redirect_uri()`](https://pedrobtz.github.io/azr/reference/default_redirect_uri.md).

- `interactive`:

  A logical value indicating whether this credential requires user
  interaction. Defaults to `TRUE`.

- `use_refresh_token`:

  A logical value indicating whether to use the login flow (acquire
  tokens via refresh token exchange). Defaults to `TRUE`.

#### Returns

A new `AuthCodeCredential` object

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AuthCodeCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# AuthCodeCredential requires an interactive session
if (FALSE) { # \dontrun{
# Create credential with default settings
cred <- AuthCodeCredential$new(
  tenant_id = "your-tenant-id",
  client_id = "your-client-id",
  scope = "https://management.azure.com/.default"
)

# Get an access token (will open browser for authentication)
token <- cred$get_token()

# Force reauthentication
token <- cred$get_token(reauth = TRUE)

# Use with httr2 request
req <- httr2::request("https://management.azure.com/subscriptions")
req <- cred$req_auth(req)
} # }
```
