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

- [`AuthCodeCredential$get_token()`](#method-AuthCodeCredential-get_token)

- [`AuthCodeCredential$req_auth()`](#method-AuthCodeCredential-req_auth)

- [`AuthCodeCredential$clone()`](#method-AuthCodeCredential-clone)

Inherited methods

- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)
- [`azr::Credential$validate()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-validate)
- [`azr::InteractiveCredential$is_interactive()`](https://pedrobtz.github.io/azr/reference/InteractiveCredential.html#method-is_interactive)

------------------------------------------------------------------------

### Method `new()`

Create a new authorization code credential

#### Usage

    AuthCodeCredential$new(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      use_cache = "disk",
      offline = TRUE,
      redirect_uri = default_redirect_uri()
    )

#### Arguments

- `scope`:

  A character string specifying the OAuth2 scope. Defaults to `NULL`.

- `tenant_id`:

  A character string specifying the Azure Active Directory tenant ID.
  Defaults to `NULL`.

- `client_id`:

  A character string specifying the application (client) ID. Defaults to
  `NULL`.

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

#### Returns

A new `AuthCodeCredential` object

------------------------------------------------------------------------

### Method [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

Get an access token using authorization code flow

#### Usage

    AuthCodeCredential$get_token(reauth = FALSE)

#### Arguments

- `reauth`:

  A logical value indicating whether to force reauthentication. Defaults
  to `FALSE`.

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing the access token

------------------------------------------------------------------------

### Method `req_auth()`

Add OAuth authorization code authentication to an httr2 request

#### Usage

    AuthCodeCredential$req_auth(req)

#### Arguments

- `req`:

  An
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object

#### Returns

The request object with OAuth authorization code authentication
configured

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
