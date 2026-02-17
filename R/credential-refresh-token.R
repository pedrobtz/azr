# RefreshTokenCredential ----
#' Refresh token credential authentication
#'
#' @description
#' Authenticates using an existing refresh token. This credential is useful when
#' you have obtained a refresh token through another authentication flow and want
#' to use it to get new access tokens without interactive authentication.
#'
#' @details
#' The refresh token credential uses the OAuth 2.0 refresh token flow to obtain
#' new access tokens. It requires a valid refresh token that was previously
#' obtained through an interactive flow (e.g., authorization code or device code).
#'
#' This is particularly useful for:
#' \itemize{
#'   \item Non-interactive sessions where you have a pre-obtained refresh token
#'   \item Long-running applications that need to refresh tokens automatically
#'   \item Scenarios where you want to avoid repeated interactive authentication
#' }
#'
#' @field .refresh_token Character string containing the refresh token.
#'
#' @export
#' @examples
#' \dontrun{
#' # Create credential with a refresh token
#' cred <- RefreshTokenCredential$new(
#'   refresh_token = "your-refresh-token",
#'   scope = "https://management.azure.com/.default",
#'   tenant_id = "your-tenant-id",
#'   client_id = "your-client-id"
#' )
#'
#' # Get an access token
#' token <- cred$get_token()
#'
#' # Use with httr2 request
#' req <- httr2::request("https://management.azure.com/subscriptions")
#' resp <- httr2::req_perform(cred$req_auth(req))
#' }
RefreshTokenCredential <- R6::R6Class(
  classname = "RefreshTokenCredential",
  inherit = Credential,
  public = list(
    .refresh_token = NULL,

    #' @description
    #' Create a new refresh token credential
    #'
    #' @param refresh_token A character string containing the refresh token.
    #'   Defaults to [default_refresh_token()] which reads from the
    #'   `AZURE_REFRESH_TOKEN` environment variable.
    #' @param scope A character string specifying the OAuth2 scope. Defaults to `NULL`.
    #' @param tenant_id A character string specifying the Azure Active Directory
    #'   tenant ID. Defaults to `NULL`.
    #' @param client_id A character string specifying the application (client) ID.
    #'   Defaults to `NULL`.
    #'
    #' @return A new `RefreshTokenCredential` object
    initialize = function(
      refresh_token = default_refresh_token(),
      scope = NULL,
      tenant_id = NULL,
      client_id = NULL
    ) {
      self$.refresh_token <- refresh_token
      super$initialize(
        scope = scope,
        tenant_id = tenant_id,
        client_id = client_id
      )
      lockBinding(".refresh_token", self)
    },

    #' @description
    #' Validate the credential configuration
    #'
    #' @details
    #' Checks that the refresh token is provided and not NA or NULL. Calls the
    #' parent class validation method.
    validate = function() {
      super$validate()

      if (is.null(self$.refresh_token) || rlang::is_na(self$.refresh_token)) {
        cli::cli_abort("Argument {.arg refresh_token} cannot be NULL or NA.")
      }
    },

    #' @description
    #' Get an access token using the refresh token flow
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function() {
      httr2::oauth_flow_refresh(
        client = self$.oauth_client,
        refresh_token = self$.refresh_token,
        scope = self$.scope_str
      )
    },

    #' @description
    #' Add OAuth refresh token authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #'
    #' @return The request object with OAuth refresh token authentication configured
    req_auth = function(req) {
      httr2::req_oauth_refresh(
        req = req,
        client = self$.oauth_client,
        refresh_token = self$.refresh_token,
        scope = self$.scope_str
      )
    }
  )
)
