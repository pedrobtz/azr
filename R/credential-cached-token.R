#' Cached token credential authentication
#'
#' @description
#' A credential class that retrieves tokens from the cache only, without
#' triggering interactive authentication flows. This is useful for non-interactive
#' sessions where you want to use previously cached tokens from DeviceCode or
#' AuthCode credentials.
#'
#' @details
#' This credential attempts to retrieve cached tokens from a chain of interactive
#' credentials (AuthCode and DeviceCode by default). It will not prompt for new
#' authentication - it only returns tokens that are already cached.
#'
#' This is particularly useful for:
#' \itemize{
#'   \item Non-interactive R sessions (e.g., scheduled scripts, CI/CD)
#'   \item Scenarios where you've previously authenticated interactively and want
#'     to reuse those cached tokens
#' }
#'
#' @field .scope Character string specifying the authentication scope.
#' @field .tenant_id Character string specifying the tenant ID.
#' @field .client_id Character string specifying the client ID.
#' @field .use_cache Character string indicating the caching strategy.
#' @field .offline Logical indicating whether offline access is requested.
#' @field .chain List of credential classes to attempt for cached tokens.
#'
#' @export
#' @examples
#' \dontrun{
#' # Create credential with default settings
#' cred <- CachedTokenCredential$new(
#'   scope = "https://graph.microsoft.com/.default",
#'   tenant_id = "my-tenant-id"
#' )
#'
#' # Get a cached token (will fail if no cached token exists)
#' token <- cred$get_token()
#'
#' # Use with httr2 request
#' req <- httr2::request("https://graph.microsoft.com/v1.0/me")
#' req <- cred$req_auth(req)
#' }
CachedTokenCredential <- R6::R6Class(
  classname = "CachedTokenCredential",
  public = list(
    .scope = NULL,
    .tenant_id = NULL,
    .client_id = NULL,
    .use_cache = NULL,
    .offline = NULL,
    .chain = NULL,

    #' @description
    #' Create a new CachedTokenCredential object
    #'
    #' @param scope Optional character string specifying the authentication scope.
    #' @param tenant_id Optional character string specifying the tenant ID for
    #'   authentication.
    #' @param client_id Optional character string specifying the client ID for
    #'   authentication.
    #' @param use_cache Character string indicating the caching strategy. Defaults
    #'   to `"disk"`. Options include `"disk"` for disk-based caching or `"memory"`
    #'   for in-memory caching.
    #' @param offline Logical. If `TRUE`, adds 'offline_access' to the scope to
    #'   request a 'refresh_token'. Defaults to `TRUE`.
    #' @param chain A list of credential classes to attempt for cached tokens.
    #'   Defaults to AuthCodeCredential and DeviceCodeCredential.
    #'
    #' @return A new `CachedTokenCredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      use_cache = "disk",
      offline = TRUE,
      chain = cached_token_credential_chain()
    ) {
      self$.scope <- scope
      self$.tenant_id <- tenant_id
      self$.client_id <- client_id
      self$.use_cache <- use_cache
      self$.offline <- offline
      self$.chain <- chain
    },

    #' @description
    #' Check if the credential is interactive
    #'
    #' @return Always returns `FALSE` since this credential only uses cached tokens
    is_interactive = function() {
      FALSE
    },

    #' @description
    #' Get an access token from the cache
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function() {
      self$provider$get_cached_token()
    },

    #' @description
    #' Add authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #'
    #' @return The request object with authentication configured
    req_auth = function(req) {
      token <- self$get_token()
      httr2::req_auth_bearer_token(req, token$access_token)
    }
  ),
  active = list(
    #' @field provider Lazily initialized credential provider
    provider = function() {
      if (is.null(private$.provider_cache)) {
        # Run in fake interactive session and offline mode to only get cached tokens
        private$.provider_cache <- tryCatch(
          get_credential_provider(
            scope = self$.scope,
            tenant_id = self$.tenant_id,
            client_id = self$.client_id,
            use_cache = self$.use_cache,
            offline = self$.offline,
            chain = self$.chain
          ),
          error = function(e) {
            cli::cli_abort(
              "No cached tokens found in the credential chain!",
              class = "azr_cached_token_not_found",
              parent = e
            )
          }
        )
      }
      private$.provider_cache
    }
  ),
  private = list(
    .provider_cache = NULL
  )
)


#' Create Cached Token Credential Chain
#'
#' Creates the default chain of credentials to attempt for cached token retrieval.
#' The credentials are tried in order until one returns a valid cached token.
#' The default chain includes:
#' \enumerate{
#'   \item Authorization Code Credential - Cached tokens from browser-based authentication
#'   \item Device Code Credential - Cached tokens from device code flow
#' }
#'
#' @return A `credential_chain` object containing the sequence of
#'   credential providers to check for cached tokens.
#'
#' @seealso [CachedTokenCredential], [credential_chain()]
#'
#' @export
cached_token_credential_chain <- function() {
  credential_chain(
    auth_code = AuthCodeCredential,
    device_code = DeviceCodeCredential
  )
}
