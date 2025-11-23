# Azure CLI Device Code Login

Performs an interactive Azure CLI login using device code flow.
Automatically captures the device code, copies it to the clipboard, and
opens the browser for authentication.

## Usage

``` r
az_cli_login()
```

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
} # }
```
