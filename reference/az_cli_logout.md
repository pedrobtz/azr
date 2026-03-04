# Azure CLI Logout

Logs out from Azure CLI by removing all stored credentials and account
information. This function runs `az logout`.

## Usage

``` r
az_cli_logout()
```

## Value

Invisibly returns `NULL`

## Details

After logging out, you will need to run
[`az_cli_login()`](https://pedrobtz.github.io/azr/reference/az_cli_login.md)
again to authenticate and use Azure CLI credentials.
