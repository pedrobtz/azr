#' Get default Azure tenant ID
#'
#' @description
#' Retrieves the Azure tenant ID in priority order:
#' 1. `AZURE_TENANT_ID` environment variable
#' 2. Built-in fallback (`"common"`)
#'
#' @return A character string with the tenant ID
#'
#' @export
#' @examples
#' default_azure_tenant_id()
default_azure_tenant_id <- function() {
  Sys.getenv(
    environment_variables$azure_tenant_id,
    unset = azure_client$tenant_id
  )
}


#' Get default Azure client ID
#'
#' @description
#' Retrieves the Azure client ID in priority order:
#' 1. `AZURE_CLIENT_ID` environment variable
#' 2. Built-in fallback (Microsoft's public Azure CLI client ID)
#'
#' @return A character string with the client ID
#'
#' @export
#' @examples
#' default_azure_client_id()
default_azure_client_id <- function() {
  Sys.getenv(
    environment_variables$azure_client_id,
    unset = azure_client$client_id
  )
}


#' Get the Azure CLI public client ID
#'
#' @description
#' Returns Microsoft's public Azure CLI client ID
#' (`04b07795-8ddb-461a-bbee-02f9e1bf7b46`). This is the default `client_id`
#' used by interactive credentials when no application-specific client ID is
#' configured.
#'
#' @return A character string with the Azure CLI client ID
#'
#' @export
#' @examples
#' default_azure_cli_client_id()
default_azure_cli_client_id <- function() {
  azure_client$client_id
}


#' Get default Azure client secret
#'
#' @description
#' Retrieves the Azure client secret from the `AZURE_CLIENT_SECRET` environment
#' variable, or returns `NA_character_` if not set.
#'
#' @return A character string with the client secret, or `NA_character_` if not set
#'
#' @export
#' @examples
#' default_azure_client_secret()
default_azure_client_secret <- function() {
  res <- Sys.getenv(
    environment_variables$azure_client_secret,
    unset = NA_character_
  )

  if (is.na(res)) {
    NULL
  } else {
    res
  }
}


#' Get default Azure refresh token
#'
#' @description
#' Retrieves the Azure refresh token from the `AZURE_REFRESH_TOKEN` environment
#' variable, or returns `NULL` if not set.
#'
#' @return A character string with the refresh token, or `NULL` if not set
#'
#' @export
#' @examples
#' default_refresh_token()
default_refresh_token <- function() {
  res <- Sys.getenv(
    environment_variables$azure_refresh_token,
    unset = NA_character_
  )

  if (is.na(res)) {
    NULL
  } else {
    res
  }
}


#' Get default Azure OAuth scope
#'
#' @description
#' Returns the default OAuth scope for a specified Azure resource.
#'
#' @param resource A character string specifying the Azure resource. Accepts
#'   both the full name (e.g. `"azure_arm"`) and the short name without the
#'   `azure_` prefix (e.g. `"arm"`). Must be one of:
#'   `"azure_arm"` / `"arm"` (Azure Resource Manager),
#'   `"azure_graph"` / `"graph"` (Microsoft Graph),
#'   `"azure_storage"` / `"storage"` (Azure Storage),
#'   `"azure_key_vault"` / `"key_vault"` (Azure Key Vault),
#'   `"azure_openai"` / `"openai"` (Azure OpenAI),
#'   `"azure_log_analytics"` / `"log_analytics"` (Azure Log Analytics),
#'   `"azure_app_insights"` / `"app_insights"` (Azure Application Insights),
#'   `"azure_databricks"` / `"databricks"` (Azure Databricks),
#'   `"azure_sql"` / `"sql"` (Azure SQL / Synapse), or
#'   `"azure_service_bus"` / `"service_bus"` (Azure Service Bus).
#'   Defaults to `"azure_arm"`.
#'
#' @return A character string with the OAuth scope URL
#'
#' @export
#' @examples
#' default_azure_scope()
#' default_azure_scope("azure_graph")
#' default_azure_scope("graph")
#' default_azure_scope("storage")
default_azure_scope <- function(resource = "azure_arm") {
  full_names <- names(azure_services)
  short_names <- sub("^azure_", "", full_names)

  if (resource %in% short_names && !resource %in% full_names) {
    resource <- paste0("azure_", resource)
  }

  resource <- rlang::arg_match(resource, values = full_names)
  paste0("https://", azure_services[[resource]]$host, "/.default")
}


#' Create default Azure OAuth client
#'
#' @description
#' Creates an [httr2::oauth_client()] configured for Azure authentication.
#'
#' @param client_id A character string specifying the client ID. Defaults to
#'   [default_azure_client_id()].
#' @param client_secret A character string specifying the client secret. Defaults
#'   to `NULL`.
#' @param name A character string specifying the client name. Defaults to `NULL`.
#'
#' @return An [httr2::oauth_client()] object
#'
#' @export
#' @examples
#' client <- default_azure_oauth_client()
#' client <- default_azure_oauth_client(
#'   client_id = "my-client-id",
#'   client_secret = "my-secret"
#' )
default_azure_oauth_client <- function(
  client_id = default_azure_client_id(),
  client_secret = NULL,
  name = NULL
) {
  httr2::oauth_client(
    name = name,
    id = client_id,
    token_url = default_azure_url("token"),
    secret = client_secret,
    auth = "body"
  )
}


#' Get default Azure OAuth URLs
#'
#' @description
#' Constructs Azure OAuth 2.0 endpoint URLs for a given tenant and authority host.
#'
#' @param endpoint A character string specifying which endpoint URL to return.
#'   Must be one of: `"authorize"`, `"token"`, or `"devicecode"`. If `NULL`
#'   (default), returns a list of all endpoint URLs.
#' @param oauth_host A character string specifying the Azure authority host.
#'   Defaults to [default_azure_host()].
#' @param tenant_id A character string specifying the tenant ID. Defaults to
#'   [default_azure_tenant_id()].
#'
#' @return If `endpoint` is specified, returns a character string with the URL.
#'   If `endpoint` is `NULL`, returns a named list of all endpoint URLs.
#'
#' @export
#' @examples
#' # Get all URLs
#' default_azure_url()
#'
#' # Get specific endpoint
#' default_azure_url("token")
#'
#' # Custom tenant
#' default_azure_url("authorize", tenant_id = "my-tenant-id")
default_azure_url <- function(
  endpoint = NULL,
  oauth_host = default_azure_host(),
  tenant_id = default_azure_tenant_id()
) {
  validate_tenant_id(tenant_id)
  oauth_host <- normalize_authority_host(oauth_host)
  oauth_base <- rlang::englue("https://{oauth_host}/{tenant_id}/oauth2/v2.0")

  urls <- c(
    authorize = paste0(oauth_base, "/authorize"),
    token = paste0(oauth_base, "/token"),
    devicecode = paste0(oauth_base, "/devicecode")
  )

  if (!is.null(endpoint)) {
    endpoint <- rlang::arg_match(endpoint, values = names(urls))
    return(urls[[endpoint]])
  }

  as.list(urls)
}


#' Get default Azure authority host
#'
#' @description
#' Retrieves the Azure authority host in priority order:
#' 1. `AZURE_AUTHORITY_HOST` environment variable
#' 2. Built-in fallback (`login.microsoftonline.com`)
#'
#' @return A character string with the authority host URL
#'
#' @export
#' @examples
#' default_azure_host()
default_azure_host <- function() {
  host <- Sys.getenv(
    environment_variables$azure_authority_host,
    unset = azure_authority_hosts$azure_public_cloud
  )
  normalize_authority_host(host)
}


default_azure_host_unchecked <- function() {
  host <- Sys.getenv(
    environment_variables$azure_authority_host,
    unset = azure_authority_hosts$azure_public_cloud
  )

  if (
    !is.character(host) || length(host) != 1L || is.na(host) || !nzchar(host)
  ) {
    host <- azure_authority_hosts$azure_public_cloud
  }

  normalize_authority_host_unchecked(host)
}

# Single source of truth for authority-host normalization: strip an optional
# `https?://` scheme and any trailing slashes, returning a bare host string.
# Callers that want a URL prepend `https://` themselves.
normalize_authority_host <- function(host, arg = rlang::caller_arg(host)) {
  if (!rlang::is_string(host) || !nzchar(host)) {
    cli::cli_abort(
      "{.arg {arg}} must be a non-empty string, not {.obj_type_friendly {host}}"
    )
  }
  host <- sub("/+$", "", host)
  sub("^https?://", "", host)
}


normalize_authority_host_unchecked <- function(host) {
  if (!is.character(host) || length(host) != 1L || is.na(host)) {
    return("")
  }

  host <- sub("/+$", "", host)
  sub("^https?://", "", host)
}


default_azure_url_unchecked <- function(
  endpoint = NULL,
  oauth_host = default_azure_host_unchecked(),
  tenant_id = default_azure_tenant_id()
) {
  oauth_host <- normalize_authority_host_unchecked(oauth_host)
  if (!nzchar(oauth_host)) {
    oauth_host <- azure_authority_hosts$azure_public_cloud
  }

  if (
    !is.character(tenant_id) ||
      length(tenant_id) != 1L ||
      is.na(tenant_id) ||
      !nzchar(tenant_id)
  ) {
    tenant_id <- azure_client$tenant_id
  }

  oauth_base <- rlang::englue("https://{oauth_host}/{tenant_id}/oauth2/v2.0")
  urls <- c(
    authorize = paste0(oauth_base, "/authorize"),
    token = paste0(oauth_base, "/token"),
    devicecode = paste0(oauth_base, "/devicecode")
  )

  if (!is.null(endpoint)) {
    if (!endpoint %in% names(urls)) {
      return(NA_character_)
    }
    return(urls[[endpoint]])
  }

  as.list(urls)
}

#' Get default Azure Storage DFS endpoint suffix
#'
#' @description
#' Returns the default endpoint suffix used to construct Azure Data Lake Storage
#' Gen2 DFS URLs.
#'
#' @return A character string with the DFS endpoint suffix.
#'
#' @export
#' @examples
#' default_storage_endpoint()
default_storage_endpoint <- function() {
  azure_services$azure_storage$dfs
}

#' Get default Azure Log Analytics query endpoint
#'
#' @description
#' Returns the default host used to construct Azure Log Analytics query URLs
#' (`api.loganalytics.io`).
#'
#' @return A character string with the Log Analytics query endpoint host.
#'
#' @export
#' @examples
#' default_log_analytics_endpoint()
default_log_analytics_endpoint <- function() {
  azure_services$azure_log_analytics$host
}

#' Get default Microsoft Graph endpoint
#'
#' @description
#' Returns the default host used to construct Microsoft Graph API URLs
#' (`graph.microsoft.com`).
#'
#' @return A character string with the Microsoft Graph endpoint host.
#'
#' @export
#' @examples
#' default_graph_endpoint()
default_graph_endpoint <- function() {
  azure_services$azure_graph$host
}

#' Get default Azure configuration directory
#'
#' @description
#' Retrieves the Azure configuration directory from the `AZURE_CONFIG_DIR`
#' environment variable, or falls back to the platform-specific default.
#'
#' @return A character string with the Azure configuration directory path
#'
#' @export
#' @examples
#' default_azure_config_dir()
default_azure_config_dir <- function() {
  Sys.getenv(
    "AZURE_CONFIG_DIR",
    unset = if (.Platform$OS.type == "windows") {
      normalizePath(
        file.path(Sys.getenv("USERPROFILE"), ".azure"),
        winslash = "/",
        mustWork = FALSE
      )
    } else {
      "~/.azure"
    }
  )
}

#' Get default MSAL token cache path
#'
#' @description
#' Returns the path to the MSAL token cache file shared by the Azure CLI and
#' Azure SDKs. Defaults to `msal_token_cache.json` inside the Azure config
#' directory (see [default_azure_config_dir()]).
#'
#' @return A character string with the path to the MSAL token cache file.
#'
#' @seealso [default_azure_config_dir()], [write_msal_token()]
#'
#' @export
default_msal_token_cache <- function() {
  file.path(default_azure_config_dir(), "msal_token_cache.json")
}


#' Get default OAuth redirect URI
#'
#' @description
#' Constructs a redirect URI for OAuth flows. If the provided URI doesn't have
#' a port, assigns a random port using [httpuv::randomPort()].
#'
#' @param redirect_uri A character string specifying the redirect URI. Defaults
#'   to [httr2::oauth_redirect_uri()].
#'
#' @return A character string with the redirect URI
#'
#' @export
#' @examples
#' default_redirect_uri()
default_redirect_uri <- function(redirect_uri = httr2::oauth_redirect_uri()) {
  parsed <- httr2::url_parse(redirect_uri)

  if (is.null(parsed$port)) {
    parsed$port <- random_port()
  }

  httr2::url_build(parsed)
}

#' Get default federated token file path
#'
#' @description
#' Retrieves the path to the federated identity token file from the
#' `AZURE_FEDERATED_TOKEN_FILE` environment variable, or returns `NULL` if
#' not set. Used by [WorkloadIdentityCredential].
#'
#' @return A character string with the file path, or `NULL` if not set
#'
#' @export
#' @examples
#' default_federated_token_file()
default_federated_token_file <- function() {
  res <- Sys.getenv(
    environment_variables$azure_federated_token_file,
    unset = NA_character_
  )

  if (is.na(res)) NULL else res
}
