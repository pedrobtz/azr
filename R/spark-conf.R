#' Azure Storage Spark / Hadoop configuration
#'
#' @description
#' Builds the named list of Hadoop `fs.azure.*` configuration keys required to
#' authenticate Apache Spark (or any ABFS-compatible runtime) against Azure Data
#' Lake Storage Gen2 via OAuth 2.0. The returned list can be passed directly to
#' `SparkSession.conf.set()`, a Databricks cluster's Spark config, or any other
#' mechanism that accepts key-value Hadoop properties.
#'
#' Three authentication types are supported:
#' \describe{
#'   \item{`"client_secret"`}{Service principal with client secret
#'     (`ClientCredsTokenProvider`).}
#'   \item{`"refresh_token"`}{Delegated user identity via a refresh token
#'     (`RefreshTokenBasedTokenProvider`).}
#'   \item{`"workload_identity"`}{Managed identity / workload identity
#'     (`MsiTokenProvider`). Suitable for AKS pods with workload identity
#'     enabled or Azure-hosted runtimes with a managed identity.}
#' }
#'
#' @param type Authentication type. One of `"client_secret"`,
#'   `"refresh_token"`, or `"workload_identity"`.
#' @param storage Optional storage account name (e.g. `"mystorageaccount"`).
#'   When `NULL` (default) the keys are applied globally to all storage
#'   accounts. When a name is supplied the keys are scoped to
#'   `<storage>.dfs.core.windows.net` only.
#' @param tenant_id Azure tenant ID. Defaults to [default_azure_tenant_id()].
#' @param client_id Azure application (client) ID. Defaults to
#'   [default_azure_client_id()].
#' @param client_secret Client secret. Required when
#'   `type = "client_secret"`. Defaults to [default_azure_client_secret()].
#' @param refresh_token Refresh token. Required when
#'   `type = "refresh_token"`. Defaults to [default_refresh_token()].
#'
#' @return A named list of Hadoop `fs.azure.*` key-value pairs.
#'
#' @export
#' @examples
#' # Global client-secret config (applies to all storage accounts)
#' azure_spark_storage_conf(
#'   type = "client_secret",
#'   tenant_id = "my-tenant",
#'   client_id = "my-client",
#'   client_secret = "my-secret"
#' )
#'
#' # Scoped to a specific storage account
#' azure_spark_storage_conf(
#'   type = "client_secret",
#'   storage = "mystorageaccount",
#'   tenant_id = "my-tenant",
#'   client_id = "my-client",
#'   client_secret = "my-secret"
#' )
#'
#' \dontrun{
#' # Workload identity (reads tenant / client from environment)
#' azure_spark_storage_conf(type = "workload_identity")
#' }
azure_spark_storage_conf <- function(
  type = c("client_secret", "refresh_token", "workload_identity"),
  storage = NULL,
  tenant_id = default_azure_tenant_id(),
  client_id = default_azure_client_id(),
  client_secret = default_azure_client_secret(),
  refresh_token = default_refresh_token()
) {
  type <- rlang::arg_match(type)

  if (!is.null(storage) && (!rlang::is_string(storage) || !nzchar(storage))) {
    cli::cli_abort("{.arg storage} must be a non-empty string or {.val NULL}.")
  }

  if (type == "client_secret" && is.null(client_secret)) {
    cli::cli_abort(c(
      "{.arg client_secret} is required when {.arg type} is {.val client_secret}.",
      "i" = "Set {.envvar AZURE_CLIENT_SECRET} or pass {.arg client_secret} directly."
    ))
  }

  if (type == "refresh_token" && is.null(refresh_token)) {
    cli::cli_abort(c(
      "{.arg refresh_token} is required when {.arg type} is {.val refresh_token}.",
      "i" = "Set {.envvar AZURE_REFRESH_TOKEN} or pass {.arg refresh_token} directly."
    ))
  }

  key <- function(property) spark_conf_key(property, storage)

  switch(
    type,
    client_secret = rlang::list2(
      !!key("auth.type") := "OAuth",
      !!key("oauth.provider.type") := "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
      !!key("oauth2.client.id") := client_id,
      !!key("oauth2.client.secret") := client_secret,
      !!key("oauth2.client.endpoint") := spark_token_endpoint(tenant_id)
    ),
    refresh_token = rlang::list2(
      !!key("auth.type") := "OAuth",
      !!key("oauth.provider.type") := "org.apache.hadoop.fs.azurebfs.oauth2.RefreshTokenBasedTokenProvider",
      !!key("oauth2.client.id") := client_id,
      !!key("oauth2.refresh.token") := refresh_token,
      !!key("oauth2.client.endpoint") := spark_token_endpoint(tenant_id)
    ),
    workload_identity = rlang::list2(
      !!key("auth.type") := "OAuth",
      !!key("oauth.provider.type") := "org.apache.hadoop.fs.azurebfs.oauth2.MsiTokenProvider",
      !!key("oauth2.msi.tenant") := tenant_id,
      !!key("oauth2.client.id") := client_id
    )
  )
}


spark_conf_key <- function(property, storage = NULL) {
  if (is.null(storage)) {
    paste0("fs.azure.account.", property)
  } else {
    paste0("fs.azure.account.", property, ".", storage, ".dfs.core.windows.net")
  }
}

# ABFS driver requires the v1 token endpoint, not the v2.0 one used elsewhere
spark_token_endpoint <- function(tenant_id) {
  paste0("https://login.microsoftonline.com/", tenant_id, "/oauth2/token")
}
