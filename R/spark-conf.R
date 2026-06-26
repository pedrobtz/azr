#' Azure Storage Spark / Hadoop configuration
#'
#' @description
#' Builds the named list of Hadoop `fs.azure.*` configuration keys required to
#' authenticate Apache Spark (or any ABFS-compatible runtime) against Azure Data
#' Lake Storage Gen2. With the default `prefix = "spark.hadoop"` the returned
#' list is ready to pass to `SparkSession.builder.config()`, a Databricks
#' cluster's Spark config, or `spark-defaults.conf` — Spark forwards
#' `spark.hadoop.*` keys to Hadoop at FileSystem-init time. Pass `prefix = NULL`
#' to get the raw `fs.azure.*` form, suitable for `core-site.xml` or a
#' `sparkContext.hadoopConfiguration().set(...)` call.
#'
#' Five authentication types are supported:
#' \describe{
#'   \item{`"client_secret"`}{Service principal with client secret
#'     (`ClientCredsTokenProvider`).}
#'   \item{`"refresh_token"`}{Delegated user identity via a refresh token
#'     (`RefreshTokenBasedTokenProvider`).}
#'   \item{`"workload_identity"`}{Kubernetes workload identity via a projected
#'     service-account token file (`WorkloadIdentityTokenProvider`). Requires
#'     Hadoop 3.4.1+ / 3.5.0+ (HADOOP-18610). Stock Apache Spark 3.5 ships with
#'     Hadoop 3.3.4, so this requires Spark 4.x or a runtime that bundles a
#'     newer Hadoop (Databricks 14.3+ LTS, Synapse 3.4+).}
#'   \item{`"managed_identity"`}{Azure managed identity via IMDS
#'     (`MsiTokenProvider`). For Azure VMs, App Service, Functions, Container
#'     Instances, and AKS pods without workload identity. Pass `client_id` to
#'     select a user-assigned identity.}
#'   \item{`"shared_key"`}{Storage account key (`SharedKey` auth type). Requires
#'     `storage_account` and `account_key`; cannot be configured globally.}
#' }
#'
#' Sovereign clouds (Azure US Government, Azure China) are supported by passing
#' the matching `authority_host` (e.g. `"login.microsoftonline.us"`). The
#' storage endpoint suffix used to scope keys to a specific account is derived
#' from the authority host. Alternatively, pass a fully qualified
#' `storage_account` like `"myacct.dfs.core.usgovcloudapi.net"` to override the
#' derivation entirely.
#'
#' @param auth_type Authentication type. One of `"refresh_token"` (default),
#'   `"client_secret"`, `"workload_identity"`, `"managed_identity"`, or
#'   `"shared_key"`.
#' @param storage_account Optional storage account, either a short name
#'   (`"myacct"`) or a fully qualified host (`"myacct.dfs.core.windows.net"`).
#'   When `NULL` (default) the keys are applied globally to all accounts. When a
#'   short name is supplied the endpoint suffix is derived from
#'   `authority_host`. Required for `auth_type = "shared_key"`.
#' @param tenant_id Azure tenant ID. Defaults to [default_azure_tenant_id()].
#' @param client_id Azure application (client) ID. Defaults to
#'   [default_azure_client_id()]. For `auth_type = "managed_identity"` this
#'   selects a user-assigned identity (omit or leave at default for
#'   system-assigned).
#' @param client_secret Client secret. Required when
#'   `auth_type = "client_secret"`. Defaults to [default_azure_client_secret()].
#' @param refresh_token Refresh token. Required when
#'   `auth_type = "refresh_token"`. Defaults to [default_refresh_token()].
#' @param account_key Storage account access key. Required when
#'   `auth_type = "shared_key"`.
#' @param token_file Path to the federated service-account token file. Used
#'   only when `auth_type = "workload_identity"`. Defaults to
#'   [default_federated_token_file()] (`AZURE_FEDERATED_TOKEN_FILE`).
#' @param authority_host Azure authority host (without scheme), e.g.
#'   `"login.microsoftonline.com"`. Used to build the OAuth token endpoint for
#'   `client_secret` and `refresh_token`, the MSI authority for
#'   `workload_identity` and `managed_identity`, and to derive the storage
#'   endpoint suffix for sovereign clouds. Defaults to [default_azure_host()].
#' @param prefix Optional prefix prepended to every returned key. Defaults to
#'   `"spark.hadoop"`, the prefix Spark uses to forward properties to Hadoop.
#'   Pass `NULL` to get the raw `fs.azure.*` keys (e.g. for `core-site.xml` or
#'   a `hadoopConfiguration()` call). A trailing dot in `prefix` is optional.
#'
#' @return A named list of class `azure_spark_config`. With the default
#'   `prefix`, keys look like `spark.hadoop.fs.azure.account.*`; with
#'   `prefix = NULL`, keys look like `fs.azure.account.*`. The `print` method
#'   redacts sensitive values (account key, client secret, refresh token).
#'
#' @export
#' @examples
#' # Global client-secret config (applies to all storage accounts)
#' azure_spark_storage_conf(
#'   auth_type = "client_secret",
#'   tenant_id = "my-tenant",
#'   client_id = "my-client",
#'   client_secret = "my-secret"
#' )
#'
#' # Scoped to a specific storage account
#' azure_spark_storage_conf(
#'   auth_type = "client_secret",
#'   storage_account = "mystorageaccount",
#'   tenant_id = "my-tenant",
#'   client_id = "my-client",
#'   client_secret = "my-secret"
#' )
#'
#' # Azure US Government sovereign cloud
#' azure_spark_storage_conf(
#'   auth_type = "client_secret",
#'   storage_account = "mystorageaccount",
#'   tenant_id = "my-tenant",
#'   client_id = "my-client",
#'   client_secret = "my-secret",
#'   authority_host = "login.microsoftonline.us"
#' )
#'
#' \dontrun{
#' # Workload identity on AKS (reads env vars automatically)
#' azure_spark_storage_conf(auth_type = "workload_identity")
#'
#' # Managed identity on an Azure VM (system-assigned)
#' azure_spark_storage_conf(auth_type = "managed_identity")
#' }
azure_spark_storage_conf <- function(
  auth_type = c(
    "refresh_token",
    "client_secret",
    "workload_identity",
    "managed_identity",
    "shared_key"
  ),
  storage_account = NULL,
  tenant_id = default_azure_tenant_id(),
  client_id = default_azure_client_id(),
  client_secret = default_azure_client_secret(),
  refresh_token = default_refresh_token(),
  account_key = NULL,
  token_file = default_federated_token_file(),
  authority_host = default_azure_host(),
  prefix = "spark.hadoop"
) {
  auth_type <- rlang::arg_match(auth_type)

  if (
    !is.null(prefix) &&
      (!rlang::is_string(prefix) || !nzchar(prefix))
  ) {
    cli::cli_abort(
      "{.arg prefix} must be a non-empty string or {.val NULL}."
    )
  }

  if (
    !is.null(storage_account) &&
      (!rlang::is_string(storage_account) || !nzchar(storage_account))
  ) {
    cli::cli_abort(
      "{.arg storage_account} must be a non-empty string or {.val NULL}."
    )
  }

  if (auth_type == "client_secret" && is.null(client_secret)) {
    cli::cli_abort(c(
      "{.arg client_secret} is required when {.arg auth_type} is {.val client_secret}.",
      "i" = "Set {.envvar AZURE_CLIENT_SECRET} or pass {.arg client_secret} directly."
    ))
  }

  if (auth_type == "refresh_token" && is.null(refresh_token)) {
    cli::cli_abort(c(
      "{.arg refresh_token} is required when {.arg auth_type} is {.val refresh_token}.",
      "i" = "Set {.envvar AZURE_REFRESH_TOKEN} or pass {.arg refresh_token} directly."
    ))
  }

  if (auth_type == "workload_identity" && is.null(token_file)) {
    cli::cli_abort(c(
      "{.arg token_file} is required when {.arg auth_type} is {.val workload_identity}.",
      "i" = "Set {.envvar AZURE_FEDERATED_TOKEN_FILE} or pass {.arg token_file} directly."
    ))
  }

  if (auth_type == "shared_key") {
    if (is.null(storage_account)) {
      cli::cli_abort(
        "{.arg storage_account} is required when {.arg auth_type} is {.val shared_key}."
      )
    }
    if (is.null(account_key)) {
      cli::cli_abort(
        "{.arg account_key} is required when {.arg auth_type} is {.val shared_key}."
      )
    }
  }

  storage_fqdn <- spark_storage_fqdn(storage_account, authority_host)
  key <- function(property) spark_conf_key(property, storage_fqdn, prefix)

  conf <- switch(
    auth_type,
    client_secret = rlang::list2(
      !!key("auth.type") := "OAuth",
      !!key(
        "oauth.provider.type"
      ) := "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
      !!key("oauth2.client.id") := client_id,
      !!key("oauth2.client.secret") := client_secret,
      !!key("oauth2.client.endpoint") := default_azure_url(
        "token",
        oauth_host = authority_host,
        tenant_id = tenant_id
      )
    ),
    refresh_token = rlang::list2(
      !!key("auth.type") := "OAuth",
      !!key(
        "oauth.provider.type"
      ) := "org.apache.hadoop.fs.azurebfs.oauth2.RefreshTokenBasedTokenProvider",
      !!key("oauth2.client.id") := client_id,
      !!key("oauth2.refresh.token") := refresh_token,
      # RefreshTokenBasedTokenProvider reads `refresh.token.endpoint`, not
      # `client.endpoint` — the latter is silently ignored for this flow.
      !!key("oauth2.refresh.token.endpoint") := default_azure_url(
        "token",
        oauth_host = authority_host,
        tenant_id = tenant_id
      )
    ),
    workload_identity = rlang::list2(
      !!key("auth.type") := "OAuth",
      !!key(
        "oauth.provider.type"
      ) := "org.apache.hadoop.fs.azurebfs.oauth2.WorkloadIdentityTokenProvider",
      !!key("oauth2.client.id") := client_id,
      !!key("oauth2.msi.tenant") := tenant_id,
      !!key("oauth2.token.file") := token_file,
      !!key("oauth2.msi.authority") := msi_authority(authority_host)
    ),
    managed_identity = rlang::list2(
      !!key("auth.type") := "OAuth",
      !!key(
        "oauth.provider.type"
      ) := "org.apache.hadoop.fs.azurebfs.oauth2.MsiTokenProvider",
      !!key("oauth2.client.id") := client_id,
      !!key("oauth2.msi.tenant") := tenant_id,
      !!key("oauth2.msi.authority") := msi_authority(authority_host)
    ),
    shared_key = rlang::list2(
      !!key("auth.type") := "SharedKey",
      !!key("key") := account_key
    )
  )
  azure_spark_config(conf)
}


azure_spark_config <- function(x) {
  structure(x, class = c("azure_spark_config", "list"))
}


spark_conf_key <- function(property, storage_fqdn = NULL, prefix = NULL) {
  base <- if (is.null(storage_fqdn)) {
    paste0("fs.azure.account.", property)
  } else {
    paste0("fs.azure.account.", property, ".", storage_fqdn)
  }
  if (is.null(prefix)) {
    return(base)
  }
  paste0(sub("\\.+$", "", prefix), ".", base)
}

# Resolve `storage_account` to a fully qualified DFS host. A short name is
# expanded with the suffix derived from `authority_host`; an FQDN (containing a
# dot) is used verbatim. Returns NULL when `storage_account` is NULL.
spark_storage_fqdn <- function(storage_account, authority_host) {
  if (is.null(storage_account)) {
    return(NULL)
  }
  if (grepl(".", storage_account, fixed = TRUE)) {
    return(storage_account)
  }
  paste0(storage_account, ".", spark_storage_suffix(authority_host))
}

# Map Azure authority host → DFS endpoint suffix for the matching cloud.
spark_storage_suffix <- function(authority_host) {
  host <- sub("/+$", "", sub("^https?://", "", authority_host))
  switch(
    host,
    "login.microsoftonline.us" = "dfs.core.usgovcloudapi.net",
    "login.chinacloudapi.cn" = "dfs.core.chinacloudapi.cn",
    "dfs.core.windows.net"
  )
}

# WorkloadIdentityTokenProvider and MsiTokenProvider build their token URLs by
# literal string concatenation: `authority + tenantId + "/oauth2/v2.0/token"`.
# The Hadoop default has a trailing `/`, so this value must end with one.
msi_authority <- function(authority_host) {
  paste0("https://", normalize_authority_host(authority_host), "/")
}
