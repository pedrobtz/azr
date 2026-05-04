# Set package-level Azure defaults

Overrides the built-in fallback values used by
[`default_azure_host()`](https://pedrobtz.github.io/azr/reference/default_azure_host.md),
[`default_azure_client_id()`](https://pedrobtz.github.io/azr/reference/default_azure_client_id.md),
and
[`default_azure_tenant_id()`](https://pedrobtz.github.io/azr/reference/default_azure_tenant_id.md)
when the corresponding environment variable is not set. Pass `NULL` to a
parameter to clear a previously set override.

The priority order for each default is:

1.  Package-level override set by `set_azr_defaults()` (highest)

2.  Environment variable (`AZURE_AUTHORITY_HOST`, `AZURE_CLIENT_ID`,
    `AZURE_TENANT_ID`)

3.  Built-in fallback (lowest)

## Usage

``` r
set_azr_defaults(
  host = .azr_defaults$host,
  client_id = .azr_defaults$client_id,
  tenant_id = .azr_defaults$tenant_id
)
```

## Arguments

- host:

  A character string specifying the Azure authority host, or `NULL` to
  clear any previously set override.

- client_id:

  A character string specifying the Azure client ID, or `NULL` to clear
  any previously set override.

- tenant_id:

  A character string specifying the Azure tenant ID, or `NULL` to clear
  any previously set override.

## Value

Invisibly returns the previous values as a named list.

## Examples

``` r
# Override the authority host for Azure Government
set_azr_defaults(host = "login.microsoftonline.us")

# Clear the override
set_azr_defaults(host = NULL)
```
