#' Get Default Token Provider Function
#'
#' Creates a token provider function that retrieves authentication credentials
#' and returns a callable token getter. This function handles the credential
#' discovery process and returns the token acquisition method from the
#' discovered credential object.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to request a 'refresh_token'.
#'   Defaults to `TRUE`.
#' @param .chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
#' @param .silent Logical. If `FALSE`, prints detailed diagnostic information
#'   during credential discovery and authentication. Defaults to `TRUE`.
#'
#' @return A function that retrieves and returns an authentication token when
#'   called.
#'
#' @seealso [get_request_authorizer()], [get_token()]
#'
#' @examples
#' # In non-interactive sessions, this function will return an error if the
#' # environment is not set up with valid credentials. In an interactive session
#' # the user will be prompted to attempt one of the interactive authentication flows.
#' \dontrun{
#' token_provider <- get_token_provider(
#'   scope = "https://graph.microsoft.com/.default",
#'   tenant_id = "my-tenant-id",
#'   client_id = "my-client-id",
#'   client_secret = "my-secret"
#' )
#' token <- token_provider()
#' }
#'
#' @export
get_token_provider <- function(scope = NULL,
                               tenant_id = NULL,
                               client_id = NULL,
                               client_secret = NULL,
                               use_cache = "disk",
                               offline = TRUE,
                               .chain = default_credential_chain(),
                               .silent = TRUE) {
  crd <- find_credential(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    .chain = .chain,
    .silent = .silent
  )

  if (isFALSE(.silent)) {
    print(crd)
  }

  function() {
    crd$get_token()
  }
}

#' Get Default Request Authorizer Function
#'
#' Creates a request authorizer function that retrieves authentication credentials
#' and returns a callable request authorization method. This function handles the
#' credential discovery process and returns the request authentication method
#' from the discovered credential object.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to request a 'refresh_token'.
#'   Defaults to `TRUE`.
#' @param .chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
#' @param .silent Logical. If `FALSE`, prints detailed diagnostic information
#'   during credential discovery and authentication. Defaults to `TRUE`.
#'
#' @return A function that authorizes HTTP requests with appropriate credentials
#'   when called.
#'
#'
#' @seealso [get_token_provider()], [get_token()]
#'
#' @examples
#' # In non-interactive sessions, this function will return an error if the
#' # environment is not setup with valid credentials. And in an interactive session
#' # the user will be prompted to attempt one of the interactive authentication flows.
#' \dontrun{
#' req_auth <- get_request_authorizer(
#'   scope = "https://graph.microsoft.com/.default"
#' )
#' req <- req_auth(httr2::request("https://graph.microsoft.com/v1.0/me"))
#' }
#'
#' @export
get_request_authorizer <- function(scope = NULL,
                                   tenant_id = NULL,
                                   client_id = NULL,
                                   client_secret = NULL,
                                   use_cache = "disk",
                                   offline = TRUE,
                                   .chain = default_credential_chain(),
                                   .silent = TRUE) {
  crd <- find_credential(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    .chain = .chain,
    .silent = .silent
  )

  function(req) {
    crd$req_auth(req)
  }
}

#' Get Authentication Token
#'
#' Retrieves an authentication token using the default token provider. This is
#' a convenience function that combines credential discovery and token
#' acquisition in a single step.
#'
#' @param scope Optional character string specifying the authentication scope.
#' @param tenant_id Optional character string specifying the tenant ID for
#'   authentication.
#' @param client_id Optional character string specifying the client ID for
#'   authentication.
#' @param client_secret Optional character string specifying the client secret
#'   for authentication.
#' @param use_cache Character string indicating the caching strategy. Defaults
#'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
#'   for in-memory caching.
#' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to request a 'refresh_token'.
#'   Defaults to `TRUE`.
#' @param .chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
#' @param .silent Logical. If `FALSE`, prints detailed diagnostic information
#'   during credential discovery and authentication. Defaults to `TRUE`.
#'
#' @return An [httr2::oauth_token()] object.
#'
#' @seealso [get_token_provider()], [get_request_authorizer()]
#'
#' @examples
#' # In non-interactive sessions, this function will return an error if the
#' # environment is not setup with valid credentials. And in an interactive session
#' # the user will be prompted to attempt one of the interactive authentication flows.
#' \dontrun{
#' token <- get_token(
#'   scope = "https://graph.microsoft.com/.default",
#'   tenant_id = "my-tenant-id",
#'   client_id = "my-client-id",
#'   client_secret = "my-secret"
#' )
#' }
#'
#' @export
get_token <- function(scope = NULL,
                      tenant_id = NULL,
                      client_id = NULL,
                      client_secret = NULL,
                      use_cache = "disk",
                      offline = TRUE,
                      .chain = default_credential_chain(),
                      .silent = TRUE) {
  provider <- get_token_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    .chain = .chain,
    .silent = .silent
  )

  provider()
}


find_credential <- function(scope = NULL,
                            tenant_id = NULL,
                            client_id = NULL,
                            client_secret = NULL,
                            use_cache = "disk",
                            offline = FALSE,
                            oauth_host = NULL,
                            oauth_endpoint = NULL,
                            .chain = NULL,
                            .silent = TRUE) {
  if (is.null(.chain) || length(.chain) == 0L) {
    .chain <- default_credential_chain()
  }

  if (!inherits(.chain, "credential_chain")) {
    cli::cli_abort("Argument {.arg .chain} must be of class {.cls credential_chain}.")
  }

  for (crd_expr in .chain) {
    crd <- try(rlang::eval_tidy(crd_expr), silent = .silent)

    if (R6::is.R6Class(crd)) {
      obj <- try(new_instance(crd, env = rlang::current_env()), silent = .silent)

      if (inherits(obj, "try-error") || !inherits(obj, "Credential")) {
        next
      }
    } else if (R6::is.R6(crd) && inherits(crd, "Credential")) {
      obj <- crd
    } else {
      next
    }

    if (isFALSE(.silent)) {
      cli::cli_alert_info("Trying: {.cls {class(obj)[[1]]}}")
    }

    if (obj$is_interactive() && !rlang::is_interactive()) {
      if (isFALSE(.silent)) {
        cli::cli_alert_warning("Skipping (non-interactive session)")
      }
      next
    }

    token <- tryCatch(
      obj$get_token(),
      error = function(e) {
        if (isFALSE(.silent)) {
          print(e)
        }
        NULL
      },
      interrupt = function(e) {
        if (isFALSE(.silent)) {
          cli::cli_alert_danger("Interrupted!")
        }
        NULL
      }
    )

    if (inherits(token, "httr2_token")) {
      if (isFALSE(.silent)) {
        cli::cli_alert_danger("Successful!")
      }
      return(obj)
    }
  }

  cli::cli_abort("All authentication methods in the chain failed!")
}


#' Create Default Credential Chain
#'
#' Creates the default chain of credentials to attempt during authentication.
#' The credentials are tried in order until one successfully authenticates.
#' The default chain includes:
#' \enumerate{
#'   \item Client Secret Credential - Uses client ID and secret
#'   \item Azure CLI Credential - Uses credentials from Azure CLI
#'   \item Authorization Code Credential - Interactive browser-based authentication
#'   \item Device Code Credential - Interactive device code flow
#' }
#'
#' @return A `credential_chain` object containing the default sequence of
#'   credential providers.
#'
#' @seealso [credential_chain()], [get_token_provider()]
#'
#' @export
default_credential_chain <- function() {
  credential_chain(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential,
    auth_code = AuthCodeCredential,
    device_code = DeviceCodeCredential
  )
}


#' Create Custom Credential Chain
#'
#' Creates a custom chain of credential providers to attempt during
#' authentication. Credentials are tried in the order they are provided
#' until one successfully authenticates. This allows you to customize
#' the authentication flow beyond the default credential chain.
#'
#' @param ... Named credential objects or credential classes. Each element
#'   should be a credential class (e.g., `ClientSecretCredential`) or an
#'   instantiated credential object that inherits from the `Credential`
#'   base class. The names are used for identification purposes.
#'
#' @return A `credential_chain` object containing the specified sequence
#'   of credential providers.
#'
#' @seealso [default_credential_chain()], [get_token_provider()]
#'
#' @examples
#' # Create a custom chain with only non-interactive credentials
#' custom_chain <- credential_chain(
#'   client_secret = ClientSecretCredential,
#'   azure_cli = AzureCLICredential
#' )
#'
#' # Use the custom chain to get a token
#' \dontrun{
#' token <- get_token(
#'   scope = "https://graph.microsoft.com/.default",
#'   .chain = custom_chain
#' )
#' }
#'
#' @export
credential_chain <- function(...) {
  res <- rlang::enquos(...)
  class(res) <- c("credential_chain", class(res))
  res
}

new_instance <- function(cls, env = rlang::caller_env()) {
  cls_args <- r6_get_initialize_arguments(cls)
  cls_values <- rlang::env_get_list(nms = cls_args, default = NULL, env = env)

  eval(rlang::call2(cls$new, !!!cls_values))
}
