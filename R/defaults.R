#' Get default Azure tenant ID
#'
#' @description
#' Retrieves the Azure tenant ID from the `AZURE_TENANT_ID` environment variable,
#' or falls back to the default value if not set.
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
#' Retrieves the Azure client ID from the `AZURE_CLIENT_ID` environment variable,
#' or falls back to the default Azure CLI client ID if not set.
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


#' Get default Azure OAuth scope
#'
#' @description
#' Returns the default OAuth scope for a specified Azure resource.
#'
#' @param resource A character string specifying the Azure resource. Must be one of:
#'   `"azure_arm"` (Azure Resource Manager), `"azure_graph"` (Microsoft Graph),
#'   `"azure_storage"` (Azure Storage), or `"azure_key_vault"` (Azure Key Vault).
#'   Defaults to `"azure_arm"`.
#'
#' @return A character string with the OAuth scope URL
#'
#' @export
#' @examples
#' default_azure_scope()
#' default_azure_scope("azure_graph")
default_azure_scope <- function(resource = "azure_arm") {
  resource <- rlang::arg_match(resource, values = names(azure_scopes))
  azure_scopes[[resource]]
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
#' Retrieves the Azure authority host from the `AZURE_AUTHORITY_HOST` environment
#' variable, or falls back to Azure Public Cloud if not set.
#'
#' @return A character string with the authority host URL
#'
#' @export
#' @examples
#' default_azure_host()
default_azure_host <- function() {
  Sys.getenv(
    environment_variables$azure_authority_host,
    unset = azure_authority_hosts$azure_public_cloud
  )
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
    rlang::check_installed("httpuv", "for desktop OAuth")
    parsed$port <- httpuv::randomPort()
  }

  httr2::url_build(parsed)
}
