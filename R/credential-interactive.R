# DeviceCodeCredential ----
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
    #'
    #' @return A new `DeviceCodeCredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      use_cache = "disk",
      offline = TRUE
    ) {
      super$initialize(
        scope = scope,
        tenant_id = tenant_id,
        client_id = client_id,
        use_cache = use_cache,
        offline = offline,
        oauth_endpoint = "devicecode",
        name = "azr-device-code"
      )
    },
    #' @description
    #' Get an access token using device code flow
    #'
    #' @param reauth A logical value indicating whether to force reauthentication.
    #'   Defaults to `FALSE`.
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function(reauth = FALSE) {
      httr2::oauth_token_cached(
        client = self$.oauth_client,
        flow = httr2::oauth_flow_device,
        cache_disk = self$.use_cache == "disk",
        cache_key = self$.cache_key,
        flow_params = list(
          scope = self$.scope_str,
          auth_url = self$.oauth_url
        ),
        reauth = reauth
      )
    },
    #' @description
    #' Add OAuth device code authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #'
    #' @return The request object with OAuth device code authentication configured
    req_auth = function(req) {
      httr2::req_oauth_device(
        req = req,
        client = self$.oauth_client,
        auth_url = self$.oauth_url,
        scope = self$.scope_str,
        cache_disk = self$.use_cache == "disk",
        cache_key = self$.cache_key
      )
    }
  )
)


# AuthCodeCredential ----
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
    #'
    #' @return A new `AuthCodeCredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      use_cache = "disk",
      offline = TRUE,
      redirect_uri = default_redirect_uri()
    ) {
      super$initialize(
        scope = scope,
        tenant_id = tenant_id,
        client_id = client_id,
        use_cache = use_cache,
        offline = offline,
        oauth_endpoint = "authorize",
        name = "azr-auth-code"
      )
      unlockBinding(".redirect_uri", self)
      self$.redirect_uri <- default_redirect_uri()
      lockBinding(".redirect_uri", self)
    },
    #' @description
    #' Get an access token using authorization code flow
    #'
    #' @param reauth A logical value indicating whether to force reauthentication.
    #'   Defaults to `FALSE`.
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function(reauth = FALSE) {
      httr2::oauth_token_cached(
        client = self$.oauth_client,
        flow = httr2::oauth_flow_auth_code,
        cache_disk = self$.use_cache == "disk",
        cache_key = self$.cache_key,
        flow_params = list(
          scope = self$.scope_str,
          auth_url = self$.oauth_url,
          redirect_uri = self$.redirect_uri
        ),
        reauth = reauth
      )
    },
    #' @description
    #' Add OAuth authorization code authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #'
    #' @return The request object with OAuth authorization code authentication configured
    req_auth = function(req) {
      httr2::req_oauth_auth_code(
        req = req,
        client = self$.oauth_client,
        auth_url = self$.oauth_url,
        scope = self$.scope_str,
        redirect_uri = self$.redirect_uri,
        cache_disk = self$.use_cache == "disk",
        cache_key = self$.cache_key
      )
    }
  )
)

# InteractiveCredential ----
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
    #' @description
    #' Check if the credential is interactive
    #'
    #' @return Always returns `TRUE` for interactive credentials
    is_interactive = function() {
      TRUE
    }
  )
)
