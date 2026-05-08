# Interactive credential base class

Base class for interactive authentication credentials. This class should
not be instantiated directly; use
[DeviceCodeCredential](https://pedrobtz.github.io/azr/reference/DeviceCodeCredential.md)
or
[AuthCodeCredential](https://pedrobtz.github.io/azr/reference/AuthCodeCredential.md)
instead.

## Super class

`azr::Credential` -\> `InteractiveCredential`

## Public fields

- `use_refresh_token`:

  Logical indicating whether to use the login flow (acquire tokens via
  refresh token exchange).

- `interactive`:

  Logical indicating whether this credential requires user interaction.

## Methods

### Public methods

- [`InteractiveCredential$new()`](#method-InteractiveCredential-new)

- [`InteractiveCredential$is_interactive()`](#method-InteractiveCredential-is_interactive)

- [`InteractiveCredential$get_token()`](#method-InteractiveCredential-get_token)

- [`InteractiveCredential$req_auth()`](#method-InteractiveCredential-req_auth)

- [`InteractiveCredential$clone()`](#method-InteractiveCredential-clone)

Inherited methods

- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)
- [`azr::Credential$validate()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-validate)

------------------------------------------------------------------------

### Method `new()`

Shared initializer for interactive credentials

#### Usage

    InteractiveCredential$new(
      scope = NULL,
      tenant_id = NULL,
      client_id = default_azure_cli_client_id(),
      use_cache = "disk",
      offline = TRUE,
      interactive = TRUE,
      use_refresh_token = TRUE,
      flow_fun,
      req_auth_fun,
      oauth_endpoint,
      name,
      extra_flow_params = list()
    )

#### Arguments

- `scope`:

  A character string specifying the OAuth2 scope.

- `tenant_id`:

  Azure AD tenant ID.

- `client_id`:

  Application (client) ID. Defaults to the Azure CLI public client ID.

- `use_cache`:

  Cache type: `"disk"` or `"memory"`.

- `offline`:

  Whether to request offline access (refresh tokens).

- `interactive`:

  Whether this credential requires user interaction.

- `use_refresh_token`:

  Whether to use the login flow (acquire tokens via refresh token
  exchange). Set to `FALSE` to use the access token flow directly.

- `flow_fun`:

  The httr2 OAuth flow function (e.g.
  [httr2::oauth_flow_device](https://httr2.r-lib.org/reference/req_oauth_device.html)).

- `req_auth_fun`:

  The httr2 request auth function (e.g.
  [httr2::req_oauth_device](https://httr2.r-lib.org/reference/req_oauth_device.html)).

- `oauth_endpoint`:

  The OAuth endpoint name passed to the parent credential.

- `name`:

  The credential name passed to the parent credential.

- `extra_flow_params`:

  A named list of additional parameters merged into
  `private$.flow_params` after `scope` and `auth_url`.

------------------------------------------------------------------------

### Method `is_interactive()`

Check if the credential requires user interaction

#### Usage

    InteractiveCredential$is_interactive()

#### Returns

Logical indicating whether this credential is interactive

------------------------------------------------------------------------

### Method [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

Get an access token using the flow configured by the subclass. Returns a
valid in-object cached token immediately if one exists for the requested
scope. Otherwise attempts token acquisition in three steps: (1) return a
valid httr2-cached token without any interaction; (2) silently refresh
using an existing refresh token; (3) fall back to the configured
interactive flow. When `reauth = TRUE` all caches are bypassed and the
interactive flow is used directly.

#### Usage

    InteractiveCredential$get_token(scope = NULL, reauth = FALSE)

#### Arguments

- `scope`:

  A character string specifying the OAuth2 scope. Defaults to `NULL`,
  which uses the scope configured on the credential.

- `reauth`:

  A logical value indicating whether to force reauthentication,
  bypassing the cache and silent refresh. Defaults to `FALSE`.

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing the access token

------------------------------------------------------------------------

### Method `req_auth()`

Add OAuth authentication to an httr2 request using the flow configured
by the subclass

#### Usage

    InteractiveCredential$req_auth(req)

#### Arguments

- `req`:

  An
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object

#### Returns

The request object with OAuth authentication configured

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    InteractiveCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
