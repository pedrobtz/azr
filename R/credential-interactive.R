#' Device code credential authentication
#'
#' @description
#' Authenticates a user through the device code flow. This flow is designed for
#' devices that don't have a web browser or have input constraints.
#'
#' @details
#' The device code flow displays a code that the user must enter on another
#' device with a web browser to complete authentication. This is ideal for
#' CLI applications, headless servers, or devices without a browser.
#'
#' The credential supports token caching to avoid repeated authentication.
#' Tokens can be cached to disk or in memory.
#'
#' @export
#' @examples
#' # DeviceCodeCredential requires an interactive session
#' \dontrun{
#' # Create credential with default settings
#' cred <- DeviceCodeCredential$new()
#'
#' # Get an access token (will prompt for 'device code' flow)
#' token <- cred$get_token()
#'
#' # Force re-authentication
#' token <- cred$get_token(reauth = TRUE)
#'
#' # Use with httr2 request
#' req <- httr2::request("https://management.azure.com/subscriptions")
#' req <- cred$req_auth(req)
#' }
DeviceCodeCredential <- R6::R6Class(
  classname = "DeviceCodeCredential",
  inherit = InteractiveCredential,
  ,
  public = list(
    #' @description
    #' Create a new device code credential
    #'
    #' @param scope A character string specifying the OAuth2 scope. Defaults to `NULL`.
    #' @param tenant_id A character string specifying the Azure Active Directory
    #'   tenant ID. Defaults to `NULL`.
    #' @param client_id A character string specifying the application (client) ID.
    #'   Defaults to `NULL`.
    #' @param use_cache A character string specifying the cache type. Use `"disk"`
    #'   for disk-based caching or `"memory"` for in-memory caching. Defaults to `"disk"`.
    #' @param offline A logical value indicating whether to request offline access
    #'   (refresh tokens). Defaults to `TRUE`.
    #' @param interactive A logical value indicating whether this credential
    #'   requires user interaction. Defaults to `TRUE`.
    #' @param login A logical value indicating whether to perform an interactive
    #'   login when no valid cached credential is found. Defaults to `TRUE`.
    #'
    #' @return A new `DeviceCodeCredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      use_cache = "disk",
      offline = TRUE,
      interactive = TRUE,
      login = TRUE
    ) {
      self$interactive <- interactive
      self$.login <- login
      private$.flow <- if (self$interactive) {
        httr2::oauth_flow_device
      } else {
        \(...) rlang::abort("non-interactive session")
      }
      private$.req_auth_fun <- httr2::req_oauth_device
      super$initialize(
        scope = scope,
        tenant_id = tenant_id,
        client_id = client_id,
        use_cache = use_cache,
        offline = offline,
        oauth_endpoint = "devicecode",
        name = "azr-device-code"
      )
      private$.flow_params <- list(
        scope = self$.scope_str,
        auth_url = self$.oauth_url
      )
    }
  )
)


#' Authorization code credential authentication
#'
#' @description
#' Authenticates a user through the OAuth 2.0 authorization code flow. This
#' flow opens a web browser for the user to sign in.
#'
#' @details
#' The authorization code flow is the standard OAuth 2.0 flow for interactive
#' authentication. It requires a web browser and is suitable for applications
#' where the user can interact with a browser window.
#'
#' The credential supports token caching to avoid repeated authentication.
#' Tokens can be cached to disk or in memory. A redirect URI is required for
#' the OAuth flow to complete.
#'
#' @export
#' @examples
#' # AuthCodeCredential requires an interactive session
#' \dontrun{
#' # Create credential with default settings
#' cred <- AuthCodeCredential$new(
#'   tenant_id = "your-tenant-id",
#'   client_id = "your-client-id",
#'   scope = "https://management.azure.com/.default"
#' )
#'
#' # Get an access token (will open browser for authentication)
#' token <- cred$get_token()
#'
#' # Force reauthentication
#' token <- cred$get_token(reauth = TRUE)
#'
#' # Use with httr2 request
#' req <- httr2::request("https://management.azure.com/subscriptions")
#' req <- cred$req_auth(req)
#' }
AuthCodeCredential <- R6::R6Class(
  classname = "AuthCodeCredential",
  inherit = InteractiveCredential,
  ,
  public = list(
    #' @description
    #' Create a new authorization code credential
    #'
    #' @param scope A character string specifying the OAuth2 scope. Defaults to `NULL`.
    #' @param tenant_id A character string specifying the Azure Active Directory
    #'   tenant ID. Defaults to `NULL`.
    #' @param client_id A character string specifying the application (client) ID.
    #'   Defaults to `NULL`.
    #' @param use_cache A character string specifying the cache type. Use `"disk"`
    #'   for disk-based caching or `"memory"` for in-memory caching. Defaults to `"disk"`.
    #' @param offline A logical value indicating whether to request offline access
    #'   (refresh tokens). Defaults to `TRUE`.
    #' @param redirect_uri A character string specifying the redirect URI registered
    #'   with the application. Defaults to [default_redirect_uri()].
    #' @param interactive A logical value indicating whether this credential
    #'   requires user interaction. Defaults to `TRUE`.
    #' @param login A logical value indicating whether to perform an interactive
    #'   login when no valid cached credential is found. Defaults to `TRUE`.
    #'
    #' @return A new `AuthCodeCredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      use_cache = "disk",
      offline = TRUE,
      redirect_uri = default_redirect_uri(),
      interactive = TRUE,
      login = TRUE
    ) {
      self$interactive <- interactive
      self$.login <- login
      private$.flow <- if (self$interactive) {
        httr2::oauth_flow_auth_code
      } else {
        \(...) rlang::abort("non-interactive session")
      }
      private$.req_auth_fun <- httr2::req_oauth_auth_code

      super$initialize(
        scope = scope,
        tenant_id = tenant_id,
        client_id = client_id,
        use_cache = use_cache,
        offline = offline,
        oauth_endpoint = "authorize",
        name = "azr-auth-code"
      )
      self$.redirect_uri <- default_redirect_uri()
      lockBinding(".redirect_uri", self)
      private$.flow_params <- list(
        scope = self$.scope_str,
        auth_url = self$.oauth_url,
        redirect_uri = self$.redirect_uri
      )
    }
  )
)


#' Interactive credential base class
#'
#' @description
#' Base class for interactive authentication credentials. This class should not
#' be instantiated directly; use [DeviceCodeCredential] or [AuthCodeCredential]
#' instead.
#'
#' @keywords internal
InteractiveCredential <- R6::R6Class(
  classname = "InteractiveCredential",
  inherit = Credential,
  public = list(
    #' @field interactive Logical indicating whether this credential requires
    #'  user interaction.
    interactive = TRUE,
    #' @field .login Logical indicating whether to perform an interactive login
    #'  when no valid cached credential is found.
    .login = TRUE,
    #' @description
    #' Check if the credential requires user interaction
    #'
    #' @return Logical indicating whether this credential is interactive
    is_interactive = function() {
      self$interactive
    },
    #' @description
    #' Get an access token using the flow configured by the subclass
    #'
    #' @param reauth A logical value indicating whether to force reauthentication.
    #'   Defaults to `FALSE`.
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function(reauth = FALSE) {
      if (!reauth) {
        token <- private$get_token_silent()
        if (!is.null(token)) {
          return(token)
        }
      }

      httr2::oauth_token_cached(
        client = self$.oauth_client,
        flow = private$.flow,
        cache_disk = self$.use_cache == "disk",
        cache_key = self$.cache_key,
        flow_params = private$.flow_params,
        reauth = reauth
      )
    },
    #' @description
    #' Add OAuth authentication to an httr2 request using the flow configured
    #' by the subclass
    #'
    #' @param req An [httr2::request()] object
    #'
    #' @return The request object with OAuth authentication configured
    req_auth = function(req) {
      rlang::inject(private$.req_auth_fun(
        req = req,
        client = self$.oauth_client,
        cache_disk = self$.use_cache == "disk",
        cache_key = self$.cache_key,
        !!!private$.flow_params
      ))
    }
  ),
  private = list(
    .flow = NULL,
    .flow_params = NULL,
    .req_auth_fun = NULL,
    # Attempt a silent token acquisition by reusing the refresh token from a
    # cached login session (same tenant/client, default ARM scope).
    # Returns an httr2_token for self$.scope, or NULL if not possible.
    get_token_silent = function() {
      login_provider <- az_login(
        tenant_id = self$.tenant_id,
        client_id = self$.client_id,
        login = self$.login
      )

      if (is.null(login_provider)) {
        return(NULL)
      }

      login_token <- tryCatch(
        login_provider$get_token(),
        error = function(e) NULL
      )

      if (is.null(login_token) || is.null(login_token$refresh_token)) {
        return(NULL)
      }

      withCallingHandlers(
        tryCatch(
          httr2::oauth_flow_refresh(
            client = self$.oauth_client,
            refresh_token = login_token$refresh_token,
            scope = self$.scope_str
          ),
          error = function(e) NULL
        ),
        warning = function(w) {
          if (
            grepl(
              "Refresh token has changed",
              conditionMessage(w),
              fixed = TRUE
            )
          ) {
            invokeRestart("muffleWarning")
          }
        }
      )
    }
  )
)

#' Log in to Azure using interactive authentication
#'
#' @description
#' Attempts to acquire an access token for the default Azure scope by trying
#' interactive authentication methods in sequence: authorization code flow
#' (browser-based) first, then device code flow as a fallback.
#'
#' @param scope A character string specifying the OAuth2 scope. Defaults to
#'   `NULL`, which uses the Azure Resource Manager scope
#'   (`"https://management.azure.com/.default"`).
#' @param tenant_id A character string specifying the Azure Active Directory
#'   tenant ID. Defaults to `NULL`, which uses the common tenant.
#' @param client_id A character string specifying the application (client) ID.
#'   Defaults to `NULL`, which uses the default Azure CLI client ID.
#' @param login A logical value. If `TRUE` (default), performs an interactive
#'   login when no valid cached credential is found. If `FALSE`, only returns
#'   a cached credential or `NULL` if none is available.
#'
#' @return Invisibly returns the authenticated credential provider object, or
#'   `NULL` if `login = FALSE` and no valid cached credential exists.
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
#' az_login(login = FALSE)
#' }
az_login <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  login = TRUE
) {
  key <- rlang::hash(list(scope, tenant_id, client_id))

  if (exists(key, envir = .login_cache, inherits = FALSE)) {
    cached <- get(key, envir = .login_cache, inherits = FALSE)
    token <- tryCatch(cached$get_token(), error = function(e) NULL)
    if (!is.null(token)) {
      return(invisible(cached))
    }
    rm(list = key, envir = .login_cache)
  }

  if (!isTRUE(login)) {
    return(invisible(NULL))
  }

  chain <- credential_chain(
    auth_code = AuthCodeCredential,
    device_code = DeviceCodeCredential
  )

  provider <- get_credential_provider(
    scope = scope,
    tenant_id = tenant_id,
    client_id = client_id,
    offline = TRUE,
    chain = chain
  )

  provider$get_token()
  assign(key, provider, envir = .login_cache)
  invisible(provider)
}
