# Azure Storage Spark / Hadoop configuration

Builds the named list of Hadoop `fs.azure.*` configuration keys required
to authenticate Apache Spark (or any ABFS-compatible runtime) against
Azure Data Lake Storage Gen2. With the default `prefix = "spark.hadoop"`
the returned list is ready to pass to `SparkSession.builder.config()`, a
Databricks cluster's Spark config, or `spark-defaults.conf` — Spark
forwards `spark.hadoop.*` keys to Hadoop at FileSystem-init time. Pass
`prefix = NULL` to get the raw `fs.azure.*` form, suitable for
`core-site.xml` or a `sparkContext.hadoopConfiguration().set(...)` call.

Five authentication types are supported:

- `"client_secret"`:

  Service principal with client secret (`ClientCredsTokenProvider`).

- `"refresh_token"`:

  Delegated user identity via a refresh token
  (`RefreshTokenBasedTokenProvider`).

- `"workload_identity"`:

  Kubernetes workload identity via a projected service-account token
  file (`WorkloadIdentityTokenProvider`). Requires Hadoop 3.4.1+ /
  3.5.0+ (HADOOP-18610). Stock Apache Spark 3.5 ships with Hadoop 3.3.4,
  so this requires Spark 4.x or a runtime that bundles a newer Hadoop
  (Databricks 14.3+ LTS, Synapse 3.4+).

- `"managed_identity"`:

  Azure managed identity via IMDS (`MsiTokenProvider`). For Azure VMs,
  App Service, Functions, Container Instances, and AKS pods without
  workload identity. Pass `client_id` to select a user-assigned
  identity.

- `"shared_key"`:

  Storage account key (`SharedKey` auth type). Requires
  `storage_account` and `account_key`; cannot be configured globally.

Sovereign clouds (Azure US Government, Azure China) are supported by
passing the matching `authority_host` (e.g.
`"login.microsoftonline.us"`). The storage endpoint suffix used to scope
keys to a specific account is derived from the authority host.
Alternatively, pass a fully qualified `storage_account` like
`"myacct.dfs.core.usgovcloudapi.net"` to override the derivation
entirely.

## Usage

``` r
azure_spark_storage_conf(
  auth_type = c("refresh_token", "client_secret", "workload_identity",
    "managed_identity", "shared_key"),
  storage_account = NULL,
  tenant_id = default_azure_tenant_id(),
  client_id = default_azure_client_id(),
  client_secret = default_azure_client_secret(),
  refresh_token = default_refresh_token(),
  account_key = NULL,
  token_file = default_federated_token_file(),
  authority_host = default_azure_host(),
  prefix = "spark.hadoop"
)
```

## Arguments

- auth_type:

  Authentication type. One of `"refresh_token"` (default),
  `"client_secret"`, `"workload_identity"`, `"managed_identity"`, or
  `"shared_key"`.

- storage_account:

  Optional storage account, either a short name (`"myacct"`) or a fully
  qualified host (`"myacct.dfs.core.windows.net"`). When `NULL`
  (default) the keys are applied globally to all accounts. When a short
  name is supplied the endpoint suffix is derived from `authority_host`.
  Required for `auth_type = "shared_key"`.

- tenant_id:

  Azure tenant ID. Defaults to
  [`default_azure_tenant_id()`](https://pedrobtz.github.io/azr/reference/default_azure_tenant_id.md).

- client_id:

  Azure application (client) ID. Defaults to
  [`default_azure_client_id()`](https://pedrobtz.github.io/azr/reference/default_azure_client_id.md).
  For `auth_type = "managed_identity"` this selects a user-assigned
  identity (omit or leave at default for system-assigned).

- client_secret:

  Client secret. Required when `auth_type = "client_secret"`. Defaults
  to
  [`default_azure_client_secret()`](https://pedrobtz.github.io/azr/reference/default_azure_client_secret.md).

- refresh_token:

  Refresh token. Required when `auth_type = "refresh_token"`. Defaults
  to
  [`default_refresh_token()`](https://pedrobtz.github.io/azr/reference/default_refresh_token.md).

- account_key:

  Storage account access key. Required when `auth_type = "shared_key"`.

- token_file:

  Path to the federated service-account token file. Used only when
  `auth_type = "workload_identity"`. Defaults to
  [`default_federated_token_file()`](https://pedrobtz.github.io/azr/reference/default_federated_token_file.md)
  (`AZURE_FEDERATED_TOKEN_FILE`).

- authority_host:

  Azure authority host (without scheme), e.g.
  `"login.microsoftonline.com"`. Used to build the OAuth token endpoint
  for `client_secret` and `refresh_token`, the MSI authority for
  `workload_identity` and `managed_identity`, and to derive the storage
  endpoint suffix for sovereign clouds. Defaults to
  [`default_azure_host()`](https://pedrobtz.github.io/azr/reference/default_azure_host.md).

- prefix:

  Optional prefix prepended to every returned key. Defaults to
  `"spark.hadoop"`, the prefix Spark uses to forward properties to
  Hadoop. Pass `NULL` to get the raw `fs.azure.*` keys (e.g. for
  `core-site.xml` or a `hadoopConfiguration()` call). A trailing dot in
  `prefix` is optional.

## Value

A named list of class `azure_spark_config`. With the default `prefix`,
keys look like `spark.hadoop.fs.azure.account.*`; with `prefix = NULL`,
keys look like `fs.azure.account.*`. The `print` method redacts
sensitive values (account key, client secret, refresh token).

## Examples

``` r
# Global client-secret config (applies to all storage accounts)
azure_spark_storage_conf(
  auth_type = "client_secret",
  tenant_id = "my-tenant",
  client_id = "my-client",
  client_secret = "my-secret"
)
#> $spark.hadoop.fs.azure.account.auth.type
#> [1] "OAuth"
#> 
#> $spark.hadoop.fs.azure.account.oauth.provider.type
#> [1] "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
#> 
#> $spark.hadoop.fs.azure.account.oauth2.client.id
#> [1] "my-client"
#> 
#> $spark.hadoop.fs.azure.account.oauth2.client.secret
#> [1] "my-secret"
#> 
#> $spark.hadoop.fs.azure.account.oauth2.client.endpoint
#> [1] "https://login.microsoftonline.com/my-tenant/oauth2/v2.0/token"
#> 
#> attr(,"class")
#> [1] "azure_spark_config" "list"              

# Scoped to a specific storage account
azure_spark_storage_conf(
  auth_type = "client_secret",
  storage_account = "mystorageaccount",
  tenant_id = "my-tenant",
  client_id = "my-client",
  client_secret = "my-secret"
)
#> $spark.hadoop.fs.azure.account.auth.type.mystorageaccount.dfs.core.windows.net
#> [1] "OAuth"
#> 
#> $spark.hadoop.fs.azure.account.oauth.provider.type.mystorageaccount.dfs.core.windows.net
#> [1] "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
#> 
#> $spark.hadoop.fs.azure.account.oauth2.client.id.mystorageaccount.dfs.core.windows.net
#> [1] "my-client"
#> 
#> $spark.hadoop.fs.azure.account.oauth2.client.secret.mystorageaccount.dfs.core.windows.net
#> [1] "my-secret"
#> 
#> $spark.hadoop.fs.azure.account.oauth2.client.endpoint.mystorageaccount.dfs.core.windows.net
#> [1] "https://login.microsoftonline.com/my-tenant/oauth2/v2.0/token"
#> 
#> attr(,"class")
#> [1] "azure_spark_config" "list"              

# Azure US Government sovereign cloud
azure_spark_storage_conf(
  auth_type = "client_secret",
  storage_account = "mystorageaccount",
  tenant_id = "my-tenant",
  client_id = "my-client",
  client_secret = "my-secret",
  authority_host = "login.microsoftonline.us"
)
#> $spark.hadoop.fs.azure.account.auth.type.mystorageaccount.dfs.core.usgovcloudapi.net
#> [1] "OAuth"
#> 
#> $spark.hadoop.fs.azure.account.oauth.provider.type.mystorageaccount.dfs.core.usgovcloudapi.net
#> [1] "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
#> 
#> $spark.hadoop.fs.azure.account.oauth2.client.id.mystorageaccount.dfs.core.usgovcloudapi.net
#> [1] "my-client"
#> 
#> $spark.hadoop.fs.azure.account.oauth2.client.secret.mystorageaccount.dfs.core.usgovcloudapi.net
#> [1] "my-secret"
#> 
#> $spark.hadoop.fs.azure.account.oauth2.client.endpoint.mystorageaccount.dfs.core.usgovcloudapi.net
#> [1] "https://login.microsoftonline.us/my-tenant/oauth2/v2.0/token"
#> 
#> attr(,"class")
#> [1] "azure_spark_config" "list"              

if (FALSE) { # \dontrun{
# Workload identity on AKS (reads env vars automatically)
azure_spark_storage_conf(auth_type = "workload_identity")

# Managed identity on an Azure VM (system-assigned)
azure_spark_storage_conf(auth_type = "managed_identity")
} # }
```
