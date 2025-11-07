# Get default Azure OAuth scope

Returns the default OAuth scope for a specified Azure resource.

## Usage

``` r
default_azure_scope(resource = "azure_arm")
```

## Arguments

- resource:

  A character string specifying the Azure resource. Must be one of:
  `"azure_arm"` (Azure Resource Manager), `"azure_graph"` (Microsoft
  Graph), `"azure_storage"` (Azure Storage), or `"azure_key_vault"`
  (Azure Key Vault). Defaults to `"azure_arm"`.

## Value

A character string with the OAuth scope URL

## Examples

``` r
default_azure_scope()
#> [1] "https://management.azure.com/.default"
default_azure_scope("azure_graph")
#> [1] "https://graph.microsoft.com/.default"
```
