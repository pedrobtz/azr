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
#' @param chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
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
get_token_provider <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  chain = default_credential_chain()
) {
  provider <- get_credential_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    chain = chain
  )

  function() {
    provider$get_token()
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
#' @param chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
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
get_request_authorizer <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  chain = default_credential_chain()
) {
  provider <- get_credential_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    chain = chain
  )

  function(req) {
    provider$req_auth(req)
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
#' @param chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds.
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
get_token <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  chain = default_credential_chain()
) {
  provider <- get_credential_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    chain = chain
  )

  provider$get_token()
}


#' Get Credential Authentication Function
#'
#' @description
#' Creates a function that retrieves authentication tokens and formats them as
#' HTTP Authorization headers. This function handles credential discovery and
#' returns a callable method that generates Bearer token headers when invoked.
#'
#' @inheritParams get_token
#'
#' @return A function that, when called, returns a named list with an
#'   `Authorization` element containing the Bearer token, suitable for use
#'   with [httr2::req_headers()].
#'
#' @seealso [get_token()], [get_request_authorizer()], [get_token_provider()]
#'
#' @examples
#' \dontrun{
#' # Create an authentication function
#' auth_fn <- get_credential_auth(
#'   scope = "https://graph.microsoft.com/.default"
#' )
#'
#' # Call it to get headers
#' auth_headers <- auth_fn()
#'
#' # Use with httr2
#' req <- httr2::request("https://graph.microsoft.com/v1.0/me") |>
#'   httr2::req_headers(!!!auth_headers)
#' }
#'
#' @export
get_credential_auth <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = TRUE,
  chain = default_credential_chain()
) {
  get_token <- get_token_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    client_secret = client_secret,
    use_cache = use_cache,
    offline = offline,
    chain = chain
  )

  function() {
    token <- get_token()
    list(Authorization = paste0("Bearer ", token$access_token))
  }
}


#' Get Credential Provider
#'
#' @description
#' Discovers and returns an authenticated credential object from a chain of
#' credential providers. This function attempts each credential in the chain
#' until one successfully authenticates, returning the first successful
#' credential object.
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
#' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to
#'   request a 'refresh_token'. Defaults to `FALSE`.
#' @param oauth_host Optional character string specifying the OAuth host URL.
#' @param oauth_endpoint Optional character string specifying the OAuth endpoint.
#' @param chain A list of credential objects, where each element must inherit
#'   from the `Credential` base class. Credentials are attempted in the order
#'   provided until `get_token` succeeds. If `NULL`, uses
#'   [default_credential_chain()].
#'
#' @return A credential object that inherits from the `Credential` class and
#'   has successfully authenticated.
#'
#' @seealso [get_token_provider()], [get_request_authorizer()],
#'   [default_credential_chain()]
#'
#' @examples
#' \dontrun{
#' # Get a credential provider with default settings
#' cred <- get_credential_provider(
#'   scope = "https://graph.microsoft.com/.default",
#'   tenant_id = "my-tenant-id"
#' )
#'
#' # Use the credential to get a token
#' token <- cred$get_token()
#' }
#'
#' @export
get_credential_provider <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  client_secret = NULL,
  use_cache = "disk",
  offline = FALSE,
  oauth_host = NULL,
  oauth_endpoint = NULL,
  chain = NULL
) {
  if (is.null(chain) || length(chain) == 0L) {
    chain <- default_credential_chain()
  }

  if (!inherits(chain, "credential_chain")) {
    cli::cli_abort(
      "Argument {.arg chain} must be of class {.cls credential_chain}."
    )
  }

  errors <- list()

  for (i in seq_along(chain)) {
    crd_expr <- chain[[i]]
    crd_name <- names(chain)[i] %||% paste0("credential_", i)

    crd <- try(rlang::eval_tidy(crd_expr), silent = TRUE)

    if (R6::is.R6Class(crd)) {
      obj <- try(
        new_instance(crd, env = rlang::current_env()),
        silent = TRUE
      )

      if (inherits(obj, "try-error")) {
        errors[[crd_name]] <- conditionMessage(attr(obj, "condition"))
        next
      }

      if (!inherits(obj, "Credential")) {
        errors[[crd_name]] <- "Object does not inherit from Credential class"
        next
      }
    } else if (R6::is.R6(crd) && inherits(crd, "Credential")) {
      obj <- crd
    } else {
      errors[[crd_name]] <- "Invalid credential type"
      next
    }

    if (obj$is_interactive() && !rlang::is_interactive()) {
      errors[[crd_name]] <- "Credential requires interactive session"
      next
    }

    token <- tryCatch(
      obj$get_token(),
      error = function(e) {
        errors[[crd_name]] <<- conditionMessage(e)
        NULL
      },
      interrupt = function(e) {
        errors[[crd_name]] <<- "Authentication interrupted by user"
        NULL
      }
    )

    if (inherits(token, "httr2_token")) {
      return(obj)
    }
  }

  # All credentials failed, report all errors
  error_msgs <- c(
    "All authentication methods in the chain failed!"
  )

  for (cred_name in names(errors)) {
    error_msgs <- c(
      error_msgs,
      "i" = paste0("{.strong ", cred_name, "}:"),
      "x" = errors[[cred_name]]
    )
  }

  cli::cli_abort(error_msgs, class = "azr_credential_chain_failed")
}


#' Create Default Credential Chain
#'
#' Creates the default chain of credentials to attempt during authentication.
#' The credentials are tried in order until one successfully authenticates.
#' The default chain includes:
#' \enumerate{
#'   \item Client Secret Credential - Uses client ID and secret
#'   \item Authorization Code Credential - Interactive browser-based authentication
#'   \item Azure CLI Credential - Uses credentials from Azure CLI
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
    auth_code = AuthCodeCredential,
    azure_cli = AzureCLICredential,
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
#'   chain = custom_chain
#' )
#' }
#'
#' @export
credential_chain <- function(...) {
  res <- rlang::enquos(...)

  if (length(res) == 0L) {
    cli::cli_abort(
      c(
        "Credential chain cannot be empty.",
        "i" = "Provide at least one credential class or instance.",
        "i" = "Use {.fn default_credential_chain} for a pre-configured chain."
      )
    )
  }

  class(res) <- c("credential_chain", class(res))
  res
}

new_instance <- function(cls, env = rlang::caller_env()) {
  cls_args <- r6_get_initialize_arguments(cls)

  if (is.null(cls_args)) {
    return(cls$new())
  }

  cls_values <- rlang::env_get_list(nms = cls_args, default = NULL, env = env)
  cls_values <- Filter(Negate(is.null), cls_values)

  eval(rlang::call2(cls$new, !!!cls_values))
}
