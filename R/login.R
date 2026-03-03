#' Log out of Azure
#'
#' @description
#' Removes a cached login session from the in-memory login cache. After calling
#' this function, the next call to [az_login()] or any credential that uses a
#' cached session will require re-authentication.
#'
#' @param tenant_id A character string specifying the Azure Active Directory
#'   tenant ID. Defaults to `NULL`.
#' @param client_id A character string specifying the application (client) ID.
#'   Defaults to `NULL`.
#' @param scope A character string specifying the OAuth2 scope. Defaults to
#'   [default_azure_scope()].
#'
#' @return Invisibly returns `TRUE` if a cached session was removed, `FALSE`
#'   otherwise.
#'
#' @export
#' @examples
#' \dontrun{
#' az_login()
#' az_logout()
#' }
az_logout <- function(
  tenant_id = NULL,
  client_id = NULL,
  scope = default_azure_scope()
) {
  key <- rlang::hash(list(scope, tenant_id, client_id))
  if (exists(key, envir = .login_cache, inherits = FALSE)) {
    rm(list = key, envir = .login_cache)
    return(invisible(TRUE))
  }
  invisible(FALSE)
}


#' Check if logged in to Azure
#'
#' @description
#' Returns `TRUE` if there is a valid cached login session for the given
#' parameters, `FALSE` otherwise. Unlike [az_login()], this function never
#' prompts for interactive authentication.
#'
#' @param tenant_id A character string specifying the Azure Active Directory
#'   tenant ID. Defaults to `NULL`.
#' @param client_id A character string specifying the application (client) ID.
#'   Defaults to `NULL`.
#' @param scope A character string specifying the OAuth2 scope. Defaults to
#'   [default_azure_scope()].
#'
#' @return `TRUE` if a valid cached session exists, `FALSE` otherwise.
#'
#' @export
#' @examples
#' \dontrun{
#' az_is_logged_in()
#' az_login()
#' az_is_logged_in() # TRUE
#' }
az_is_logged_in <- function(
  tenant_id = NULL,
  client_id = NULL,
  scope = default_azure_scope()
) {
  key <- rlang::hash(list(scope, tenant_id, client_id))
  if (!exists(key, envir = .login_cache, inherits = FALSE)) {
    return(FALSE)
  }
  cached <- get(key, envir = .login_cache, inherits = FALSE)
  token <- tryCatch(cached$get_token(), error = function(e) NULL)
  !is.null(token)
}


get_login_chain <- function(scope, tenant_id, client_id) {
  credential_chain(
    auth_code = AuthCodeCredential$new(
      scope = scope,
      tenant_id = tenant_id,
      client_id = client_id,
      interactive = TRUE
    ),
    device_code = DeviceCodeCredential$new(
      scope = scope,
      tenant_id = tenant_id,
      client_id = client_id,
      interactive = TRUE
    ),
    azure_cli = AzureCLICredential$new(
      scope = scope,
      tenant_id = tenant_id,
      interactive = TRUE,
      use_bridge = TRUE
    )
  )
}


#' Log in to Azure using interactive authentication
#'
#' @description
#' Attempts to acquire an access token for the default Azure scope by trying
#' interactive authentication methods in sequence: authorization code flow
#' (browser-based) first, then device code flow as a fallback.
#'
#' @param tenant_id A character string specifying the Azure Active Directory
#'   tenant ID. Defaults to `NULL`, which uses the common tenant.
#' @param client_id A character string specifying the application (client) ID.
#'   Defaults to `NULL`, which uses the default Azure CLI client ID.
#' @param interactive A logical value. If `TRUE`, performs an interactive login
#'   when no valid cached credential is found. If `FALSE`, only returns a cached
#'   credential or `NULL` if none is available. Defaults to
#'   [rlang::is_interactive()].
#' @param scope A character string specifying the OAuth2 scope. Defaults to
#'   [default_azure_scope()].
#'
#' @return Invisibly returns the authenticated credential provider object, or
#'   `NULL` if `interactive = FALSE` and no valid cached credential exists.
#'
#' @export
#' @examples
#' \dontrun{
#' # Log in using the default scope
#' az_login()
#'
#' # Log in with a specific scope
#' az_login(scope = "https://graph.microsoft.com/.default")
#'
#' # Log in to a specific tenant
#' az_login(tenant_id = "your-tenant-id")
#'
#' # Only retrieve a cached credential, do not prompt for login
#' az_login(interactive = FALSE)
#' }
az_login <- function(
  tenant_id = NULL,
  client_id = NULL,
  interactive = rlang::is_interactive(),
  scope = default_azure_scope(),
  chain = get_login_chain(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id
  ),
  use_cache = TRUE,
  verbose = getOption("azr.verbose", TRUE)
) {
  key <- rlang::hash(list(scope, tenant_id, client_id, chain))

  if (use_cache && exists(key, envir = .login_cache, inherits = FALSE)) {
    cached <- get(key, envir = .login_cache, inherits = FALSE)
    token <- tryCatch(cached$get_token(), error = function(e) NULL)
    if (!is.null(token)) {
      return(invisible(cached))
    }
    az_logout(
      tenant_id = tenant_id,
      client_id = client_id,
      scope = scope,
      chain = chain
    )
  }

  if (verbose) {
    cli::cli_inform(c(
      "i" = "Logging in to Azure",
      " " = "Tenant: {.val {tenant_id %||% 'common'}}",
      " " = "Client: {.val {client_id %||% 'default'}}",
      " " = "Scope:  {.val {scope}}"
    ))
  }

  provider <- get_credential_provider(chain = chain)

  token <- tryCatch(provider$get_token(), error = function(e) NULL)
  if (!inherits(token, "httr2_token")) {
    cli::cli_abort("Failed to login.")
  }
  if (use_cache) {
    assign(key, provider, envir = .login_cache)
  }
  invisible(provider)
}
