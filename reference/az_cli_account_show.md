# Show Azure CLI Account Information

Retrieves information about the currently active Azure CLI account and
subscription. This function runs `az account show` and parses the JSON
output into an R list.

## Usage

``` r
az_cli_account_show(timeout = 10L)
```

## Arguments

- timeout:

  An integer specifying the timeout in seconds for the Azure CLI
  command. Defaults to `10`.

## Value

A list containing the account information from Azure CLI

## Details

The function returns details about the current Azure subscription
including:

- Subscription ID and name

- Tenant ID

- Account state (e.g., "Enabled")

- User information

- Cloud environment details

## Examples

``` r
if (FALSE) { # \dontrun{
# Get current account information
account_info <- az_cli_account_show()

# Access subscription ID
subscription_id <- account_info$id

# Access tenant ID
tenant_id <- account_info$tenantId
} # }
```
