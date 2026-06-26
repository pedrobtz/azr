# Get default Azure OAuth scope

Returns the default OAuth scope for a specified Azure resource.

## Usage

``` r
default_azure_scope(resource = "azure_arm")
```

## Arguments

- resource:

  A character string specifying the Azure resource. Accepts both the
  full name (e.g. `"azure_arm"`) and the short name without the `azure_`
  prefix (e.g. `"arm"`). Must be one of: `"azure_arm"` / `"arm"` (Azure
  Resource Manager), `"azure_graph"` / `"graph"` (Microsoft Graph),
  `"azure_storage"` / `"storage"` (Azure Storage), `"azure_key_vault"` /
  `"key_vault"` (Azure Key Vault), `"azure_openai"` / `"openai"` (Azure
  OpenAI), `"azure_log_analytics"` / `"log_analytics"` (Azure Log
  Analytics), `"azure_app_insights"` / `"app_insights"` (Azure
  Application Insights), `"azure_databricks"` / `"databricks"` (Azure
  Databricks), `"azure_sql"` / `"sql"` (Azure SQL / Synapse), or
  `"azure_service_bus"` / `"service_bus"` (Azure Service Bus). Defaults
  to `"azure_arm"`.

## Value

A character string with the OAuth scope URL

## Examples

``` r
default_azure_scope()
#> [1] "https://management.azure.com/.default"
default_azure_scope("azure_graph")
#> [1] "https://graph.microsoft.com/.default"
default_azure_scope("graph")
#> [1] "https://graph.microsoft.com/.default"
default_azure_scope("storage")
#> [1] "https://storage.azure.com/.default"
```
