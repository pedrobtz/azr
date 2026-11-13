# Azure CLI Device Code Login

Performs an interactive Azure CLI login using device code flow.
Automatically captures the device code, copies it to the clipboard, and
opens the browser for authentication.

## Usage

``` r
az_cli_login(
  tenant_id = NULL,
  use_bridge = FALSE,
  verbose = FALSE,
  force = FALSE
)
```

## Arguments

- tenant_id:

  A character string specifying the Azure Active Directory tenant ID to
  authenticate against. If `NULL` (default), uses the default tenant
  from Azure CLI configuration.

- use_bridge:

  A logical value indicating whether to use the device code bridge
  webpage. If `TRUE`, launches an intermediate local webpage that
  displays the device code and facilitates copy-pasting before
  redirecting to the Microsoft device login page. If `FALSE` (default),
  copies the code directly to the clipboard and opens the Microsoft
  login page.

- verbose:

  A logical value indicating whether to print detailed process output to
  the console, including error messages from the Azure CLI process. If
  `FALSE` (default), only essential messages are displayed.

- force:

  A logical value. If `FALSE` (default), an existing Azure CLI login is
  reused and no new login is started. If `TRUE`, always runs `az login`,
  for example to switch accounts.

## Value

Invisibly, the current account from `az account show` when an existing
login is reused; otherwise the accounts reported by `az login` on
success, or its non-zero exit status on failure.

## Details

Unless `force = TRUE`, the function first runs `az account show` and,
when the Azure CLI is already logged in (to `tenant_id`, if given),
returns that account without starting a new login. Otherwise it runs
`az login --use-device-code`, monitors the output to extract the device
code, copies it to the clipboard, and opens the authentication URL in
the default browser.

## Examples

``` r
if (FALSE) { # interactive() && nzchar(Sys.which("az"))
# Reuses the current login if there is one
az_cli_login()

# Always start a new login
az_cli_login(force = TRUE)
}
```
