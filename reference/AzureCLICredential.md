# Azure CLI credential authentication

Authenticates using the Azure CLI (`az`) command-line tool. This
credential requires the Azure CLI to be installed and the user to be
logged in via `az login`.

## Details

The credential uses the `az account get-access-token` command to
retrieve access tokens. It will use the currently active Azure CLI
account and subscription unless a specific tenant is specified.

## Super class

`azr::Credential` -\> `AzureCLICredential`

## Public fields

- `.process_timeout`:

  Timeout in seconds for Azure CLI command execution

## Methods

### Public methods

- [`AzureCLICredential$new()`](#method-AzureCLICredential-new)

- [`AzureCLICredential$get_token()`](#method-AzureCLICredential-get_token)

- [`AzureCLICredential$req_auth()`](#method-AzureCLICredential-req_auth)

- [`AzureCLICredential$account_show()`](#method-AzureCLICredential-account_show)

- [`AzureCLICredential$login()`](#method-AzureCLICredential-login)

- [`AzureCLICredential$logout()`](#method-AzureCLICredential-logout)

- [`AzureCLICredential$clone()`](#method-AzureCLICredential-clone)

Inherited methods

- [`azr::Credential$is_interactive()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-is_interactive)
- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)
- [`azr::Credential$validate()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-validate)

------------------------------------------------------------------------

### Method `new()`

Create a new Azure CLI credential

#### Usage

    AzureCLICredential$new(
      scope = NULL,
      tenant_id = NULL,
      process_timeout = NULL,
      login = FALSE
    )

#### Arguments

- `scope`:

  A character string specifying the OAuth2 scope. Defaults to `NULL`,
  which uses the scope set during initialization.

- `tenant_id`:

  A character string specifying the Azure Active Directory tenant ID.
  Defaults to `NULL`, which uses the default tenant from Azure CLI.

- `process_timeout`:

  A numeric value specifying the timeout in seconds for the Azure CLI
  process. Defaults to `10`.

- `login`:

  A logical value indicating whether to check if the user is logged in
  and perform login if needed. Defaults to `FALSE`.

#### Returns

A new `AzureCLICredential` object

------------------------------------------------------------------------

### Method [`get_token()`](https://pedrobtz.github.io/azr/reference/get_token.md)

Get an access token from Azure CLI

#### Usage

    AzureCLICredential$get_token(scope = NULL)

#### Arguments

- `scope`:

  A character string specifying the OAuth2 scope. If `NULL`, uses the
  scope specified during initialization.

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object containing the access token

------------------------------------------------------------------------

### Method `req_auth()`

Add authentication to an httr2 request

#### Usage

    AzureCLICredential$req_auth(req, scope = NULL)

#### Arguments

- `req`:

  An
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object

- `scope`:

  A character string specifying the OAuth2 scope. If `NULL`, uses the
  scope specified during initialization.

#### Returns

The request object with authentication header added

------------------------------------------------------------------------

### Method `account_show()`

Show the currently active Azure CLI account information

#### Usage

    AzureCLICredential$account_show(timeout = NULL)

#### Arguments

- `timeout`:

  A numeric value specifying the timeout in seconds for the Azure CLI
  command. If `NULL`, uses the process timeout specified during
  initialization.

#### Returns

A list containing the account information from Azure CLI

------------------------------------------------------------------------

### Method `login()`

Perform Azure CLI login using device code flow

#### Usage

    AzureCLICredential$login()

#### Returns

Invisibly returns the exit status (0 for success, non-zero for failure)

------------------------------------------------------------------------

### Method `logout()`

Log out from Azure CLI

#### Usage

    AzureCLICredential$logout()

#### Returns

Invisibly returns `NULL`

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    AzureCLICredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# Create credential with default settings
cred <- AzureCLICredential$new()

# Create credential with specific scope and tenant
cred <- AzureCLICredential$new(
  scope = "https://management.azure.com/.default",
  tenant_id = "your-tenant-id"
)

# To get a token or authenticate a request it is required that
# 'az login' is successfully executed, otherwise it will return an error.
if (FALSE) { # \dontrun{
# Get an access token
token <- cred$get_token()

# Use with httr2 request
req <- httr2::request("https://management.azure.com/subscriptions")
resp <- httr2::req_perform(cred$req_auth(req))
} # }
```
