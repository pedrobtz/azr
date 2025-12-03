# Azure CLI Device Code Login

Performs an interactive Azure CLI login using device code flow.
Automatically captures the device code, copies it to the clipboard, and
opens the browser for authentication.

## Usage

``` r
az_cli_login(tenant_id = NULL, use_bridge = FALSE, verbose = FALSE)
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

## Value

Invisibly returns the exit status (0 for success, non-zero for failure)

## Details

This function runs `az login --use-device-code`, monitors the output to
extract the device code, copies it to the clipboard, and opens the
authentication URL in the default browser.

## Examples

``` r
if (FALSE) { # \dontrun{
# Perform Azure CLI login with device code flow
az_cli_login()

# Use the bridge webpage for easier code handling
az_cli_login(use_bridge = TRUE)

# Login to a specific tenant with verbose output
az_cli_login(tenant_id = "your-tenant-id", verbose = TRUE)
} # }
```
