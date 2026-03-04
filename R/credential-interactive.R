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
  # public ----
  public = list(
    #' @field use_refresh_token Logical indicating whether to use the login flow (acquire
    #'  tokens via refresh token exchange).
    use_refresh_token = TRUE,
    #' @field interactive Logical indicating whether this credential requires
    #'  user interaction.
    interactive = TRUE,
    #' @description
    #' Shared initializer for interactive credentials
    #'
    #' @param scope A character string specifying the OAuth2 scope.
    #' @param tenant_id Azure AD tenant ID.
    #' @param client_id Application (client) ID.
    #' @param use_cache Cache type: `"disk"` or `"memory"`.
    #' @param offline Whether to request offline access (refresh tokens).
    #' @param interactive Whether this credential requires user interaction.
    #' @param use_refresh_token Whether to use the login flow (acquire tokens via refresh token
    #'   exchange). Set to `FALSE` to use the access token flow directly.
    #' @param flow_fun The httr2 OAuth flow function (e.g. [httr2::oauth_flow_device]).
    #' @param req_auth_fun The httr2 request auth function (e.g. [httr2::req_oauth_device]).
    #' @param oauth_endpoint The OAuth endpoint name passed to the parent credential.
    #' @param name The credential name passed to the parent credential.
    #' @param extra_flow_params A named list of additional parameters merged into
    #'   `private$.flow_params` after `scope` and `auth_url`.
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      use_cache = "disk",
      offline = TRUE,
      interactive = TRUE,
      use_refresh_token = TRUE,
      flow_fun,
      req_auth_fun,
      oauth_endpoint,
      name,
      extra_flow_params = list()
    ) {
      self$interactive <- interactive
      private$.flow <- if (self$interactive) {
        flow_fun
      } else {
        \(...) cli::cli_abort("non-interactive session")
      }
      private$.req_auth_fun <- req_auth_fun
      self$use_refresh_token <- use_refresh_token

      private$.login_scope <- c(default_azure_scope(), "offline_access")

      super$initialize(
        scope = scope,
        tenant_id = tenant_id,
        client_id = client_id,
        use_cache = use_cache,
        offline = offline,
        oauth_endpoint = oauth_endpoint,
        name = name
      )
      private$.flow_params <- c(
        list(scope = self$.scope_str, auth_url = self$.oauth_url),
        extra_flow_params
      )
    },
    #' @description
    #' Check if the credential requires user interaction
    #'
    #' @return Logical indicating whether this credential is interactive
    is_interactive = function() {
      self$interactive
    },
    #' @description
    #' Get an access token using the flow configured by the subclass.
    #' Attempts token acquisition in three steps: (1) return a valid cached
    #' token without any interaction; (2) silently refresh using an existing
    #' refresh token; (3) fall back to the configured interactive flow.
    #' When `reauth = TRUE` all three steps are skipped and the interactive
    #' flow is used directly.
    #'
    #' @param scope A character string specifying the OAuth2 scope. Defaults to
    #'   `NULL`, which uses the scope configured on the credential.
    #' @param reauth A logical value indicating whether to force
    #'   reauthentication, bypassing the cache and silent refresh. Defaults to
    #'   `FALSE`.
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function(scope = NULL, reauth = FALSE) {
      if (isTRUE(self$use_refresh_token) || !is.null(scope)) {
        token <- private$do_flow_refresh_token(scope = scope)

        if (inherits(token, "httr2_token")) {
          return(token)
        } else {
          cli::cli_abort("Failed to acquire token via login refresh flow.")
        }
      }

      private$do_flow_access_token(
        scope = NULL,
        reauth = reauth,
        interactive = self$interactive
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
      token <- self$get_token()
      httr2::req_auth_bearer_token(req, token$access_token)
    }
  ),
  # private ----
  private = list(
    .flow = NULL,
    .flow_params = NULL,
    .req_auth_fun = NULL,
    .login_scope = NULL,
    # runs access token flow
    do_flow_access_token = function(
      scope = NULL,
      reauth = FALSE,
      interactive = TRUE
    ) {
      flow_params <- private$.flow_params
      cache_key <- self$.cache_key

      if (!is.null(scope)) {
        flow_params$scope <- collapse_scope(scope)
        cache_key$scope <- collapse_scope(scope)
      }
      flow <- if (interactive) {
        private$.flow
      } else {
        \(...) cli::cli_abort("non-interactive session")
      }
      httr2::oauth_token_cached(
        client = self$.oauth_client,
        flow = flow,
        cache_disk = self$.use_cache == "disk",
        cache_key = cache_key,
        flow_params = flow_params,
        reauth = reauth
      )
    },
    # Get an access token for `scope` using the refresh token from this
    # credential's own cached token. Returns an httr2_token or NULL if not
    # possible.
    do_flow_refresh_token = function(scope = NULL) {
      scope <- collapse_scope(scope %||% self$.scope)
      login_token <- tryCatch(
        private$do_flow_access_token(scope = private$.login_scope),
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
            scope = scope
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
    #' @param use_refresh_token A logical value indicating whether to use the login flow
    #'   (acquire tokens via refresh token exchange). Defaults to `TRUE`.
    #'
    #' @return A new `DeviceCodeCredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      use_cache = "disk",
      offline = TRUE,
      interactive = TRUE,
      use_refresh_token = TRUE
    ) {
      super$initialize(
        scope = scope,
        tenant_id = tenant_id,
        client_id = client_id,
        use_cache = use_cache,
        offline = offline,
        interactive = interactive,
        use_refresh_token = use_refresh_token,
        flow_fun = httr2::oauth_flow_device,
        req_auth_fun = httr2::req_oauth_device,
        oauth_endpoint = "devicecode",
        name = "azr-device-code"
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
    #' @param use_refresh_token A logical value indicating whether to use the login flow
    #'   (acquire tokens via refresh token exchange). Defaults to `TRUE`.
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
      use_refresh_token = TRUE
    ) {
      super$initialize(
        scope = scope,
        tenant_id = tenant_id,
        client_id = client_id,
        use_cache = use_cache,
        offline = offline,
        interactive = interactive,
        use_refresh_token = use_refresh_token,
        flow_fun = httr2::oauth_flow_auth_code,
        req_auth_fun = httr2::req_oauth_auth_code,
        oauth_endpoint = "authorize",
        name = "azr-auth-code",
        extra_flow_params = list(redirect_uri = redirect_uri)
      )
      self$.redirect_uri <- redirect_uri
      lockBinding(".redirect_uri", self)
    }
  )
)
