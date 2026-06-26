# Get the Azure CLI public client ID

Returns Microsoft's public Azure CLI client ID
(`04b07795-8ddb-461a-bbee-02f9e1bf7b46`). This is the default
`client_id` used by interactive credentials when no application-specific
client ID is configured.

## Usage

``` r
default_azure_cli_client_id()
```

## Value

A character string with the Azure CLI client ID

## Examples

``` r
default_azure_cli_client_id()
#> [1] "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
```
