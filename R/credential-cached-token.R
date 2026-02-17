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
    .chain = NULL,

    #' @description
    #' Create a new CachedTokenCredential object
    #'
    #' @param scope Optional character string specifying the authentication scope.
    #' @param tenant_id Optional character string specifying the tenant ID for
    #'   authentication.
    #' @param client_id Optional character string specifying the client ID for
    #'   authentication.
    #' @param chain A list of credential classes to attempt for cached tokens.
    #'   Defaults to AuthCodeCredential and DeviceCodeCredential.
    #'
    #' @return A new `CachedTokenCredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL,
      chain = cached_token_credential_chain()
    ) {
      self$.scope <- scope
      self$.tenant_id <- tenant_id
      self$.client_id <- client_id
      self$.chain <- chain
    },

    #' @description
    #' Get an access token from the cache
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function() {
      self$provider$get_token()
    },

    #' @description
    #' Add authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #'
    #' @return The request object with authentication configured
    req_auth = function(req) {
      self$provider$req_auth(req)
    }
  ),
  active = list(
    #' @field provider Lazily initialized credential provider
    provider = function() {
      if (is.null(private$.provider_cache)) {
        # Run in fake interactive session and offline mode to only get cached tokens
        private$.provider_cache <-
          get_credential_provider(
            scope = self$.scope,
            tenant_id = self$.tenant_id,
            client_id = self$.client_id,
            chain = self$.chain,
            interactive = FALSE
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
#'   \item Azure CLI Credential - Cached tokens from Azure CLI authentication
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
    device_code = DeviceCodeCredential,
    az_cli = AzureCLICredential
  )
}
