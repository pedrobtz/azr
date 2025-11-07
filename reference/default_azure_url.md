# Get default Azure OAuth URLs

Constructs Azure OAuth 2.0 endpoint URLs for a given tenant and
authority host.

## Usage

``` r
default_azure_url(
  endpoint = NULL,
  oauth_host = default_azure_host(),
  tenant_id = default_azure_tenant_id()
)
```

## Arguments

- endpoint:

  A character string specifying which endpoint URL to return. Must be
  one of: `"authorize"`, `"token"`, or `"devicecode"`. If `NULL`
  (default), returns a list of all endpoint URLs.

- oauth_host:

  A character string specifying the Azure authority host. Defaults to
  [`default_azure_host()`](https://pedrobtz.github.io/azr/reference/default_azure_host.md).

- tenant_id:

  A character string specifying the tenant ID. Defaults to
  [`default_azure_tenant_id()`](https://pedrobtz.github.io/azr/reference/default_azure_tenant_id.md).

## Value

If `endpoint` is specified, returns a character string with the URL. If
`endpoint` is `NULL`, returns a named list of all endpoint URLs.

## Examples

``` r
# Get all URLs
default_azure_url()
#> $authorize
#> [1] "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
#> 
#> $token
#> [1] "https://login.microsoftonline.com/common/oauth2/v2.0/token"
#> 
#> $devicecode
#> [1] "https://login.microsoftonline.com/common/oauth2/v2.0/devicecode"
#> 

# Get specific endpoint
default_azure_url("token")
#> [1] "https://login.microsoftonline.com/common/oauth2/v2.0/token"

# Custom tenant
default_azure_url("authorize", tenant_id = "my-tenant-id")
#> [1] "https://login.microsoftonline.com/my-tenant-id/oauth2/v2.0/authorize"
```
