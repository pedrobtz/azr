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
#' @param offline Logical. If `TRUE`, operates in offline mode. Defaults to
#'   `FALSE`.
#' @param .chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
#' @param .verbose Logical. If `TRUE`, prints detailed diagnostic information
#'   during credential discovery and authentication. Defaults to `FALSE`.
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
                               offline = FALSE,
                               .chain = default_credential_chain(),
                               .verbose = FALSE) {
  crd <- find_credential(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    .chain = .chain,
    .verbose = .verbose
  )

  crd$get_token
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
#' @param offline Logical. If `TRUE`, operates in offline mode. Defaults to
#'   `FALSE`.
#' @param .chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
#' @param .verbose Logical. If `TRUE`, prints detailed diagnostic information
#'   during credential discovery and authentication. Defaults to `FALSE`.
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
                                   offline = FALSE,
                                   .chain = default_credential_chain(),
                                   .verbose = FALSE) {
  crd <- find_credential(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    .chain = .chain,
    .verbose = .verbose
  )
  crd$req_auth
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
#' @param offline Logical. If `TRUE`, operates in offline mode. Defaults to
#'   `FALSE`.
#' @param .chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
#' @param .verbose Logical. If `TRUE`, prints detailed diagnostic information
#'   during credential discovery and authentication. Defaults to `FALSE`.
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
                      offline = FALSE,
                      .chain = default_credential_chain(),
                      .verbose = FALSE) {
  provider <- get_token_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    .chain = .chain,
    .verbose = .verbose
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
                            .verbose = FALSE) {
  if (is.null(.chain) || length(.chain) == 0L) {
    .chain <- default_credential_chain()
  }

  for (crd in .chain) {
    if (R6::is.R6Class(crd)) {
      obj <- try(new_instance(crd, env = rlang::current_env()), silent = TRUE)
      cli::cli_alert_info("Trying: {.cls {crd$classname}}")

      if (inherits(obj, "try-error") || !inherits(obj, "Credential")) {
        cli::cli_alert_danger("Unsuccessful!")
        next
      }
    } else {
      if (R6::is.R6(crd) && inherits(crd, "Credential")) {
        obj <- crd
        cli::cli_alert_info("Trying: {.cls {class(obj)[[1]]}}")
      } else {
        cli::cli_abort(c(
          "Invalid object class {.cls {class(crd)}}",
          "Object must be of class {.cls Credential}"
        ))
      }
    }

    if (obj$is_interactive() && !rlang::is_interactive()) {
      cli::cli_alert_warning("Skipping (non-interactive session)")
      next
    }

    if (isTRUE(.verbose)) {
      print(obj)
    }

    token <- tryCatch(
      obj$get_token(),
      error = function(e) {
        if (isTRUE(.verbose)) {
          print(e)
        } else {
          cli::cli_alert_danger("Unsuccessful!")
        }
        NULL
      },
      interrupt = function(e) {
        cli::cli_alert_danger("Interrupted!")
        NULL
      }
    )

    if (inherits(token, "httr2_token")) {
      cli::cli_alert_success("Successful!")
      return(obj)
    }
  }

  cli::cli_abort("All authentication methods in the chain failed!")
}


default_credential_chain <- function() {
  list(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential,
    auth_code = AuthCodeCredential,
    device_code = DeviceCodeCredential
  )
}


new_instance <- function(cls, env = rlang::caller_env()) {
  cls_args <- r6_get_initialize_arguments(cls)
  cls_values <- rlang::env_get_list(nms = cls_args, default = NULL, env = env)

  eval(rlang::call2(cls$new, !!!cls_values))
}
