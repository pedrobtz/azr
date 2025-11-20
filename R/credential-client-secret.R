# ClientSecretCredential ----
#' Client secret credential authentication
#'
#' @description
#' Authenticates a service principal using a client ID and client secret.
#' This credential is commonly used for application authentication in Azure.
#'
#' @details
#' The credential uses the OAuth 2.0 client credentials flow to obtain access
#' tokens. It requires a registered Azure AD application with a client secret.
#' The client secret should be stored securely and not hard-coded in scripts.
#'
#' @export
#' @examples
#' # Create credential with client secret
#' cred <- ClientSecretCredential$new(
#'   tenant_id = "your-tenant-id",
#'   client_id = "your-client-id",
#'   client_secret = "your-client-secret",
#'   scope = "https://management.azure.com/.default"
#' )
#'
#' # To get a token or authenticate a request it requires
#' # valid 'client_id' and 'client_secret' credentials,
#' # otherwise it will return an error.
#' \dontrun{
#' # Get an access token
#' token <- cred$get_token()
#'
#' # Use with httr2 request
#' req <- httr2::request("https://management.azure.com/subscriptions")
#' resp <- httr2::req_perform(cred$req_auth(req))
#' }
ClientSecretCredential <- R6::R6Class(
  classname = "ClientSecretCredential",
  inherit = Credential,
  public = list(
    #' @description
    #' Validate the credential configuration
    #'
    #' @details
    #' Checks that the client secret is provided and not NA or NULL. Calls the parent
    #' class validation method.
    validate = function() {
      super$validate()

      if (is.null(self$.client_secret) || rlang::is_na(self$.client_secret)) {
        cli::cli_abort("Argument {.arg client_secret} cannot be NULL or NA.")
      }
    },
    #' @description
    #' Get an access token using client credentials flow
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function() {
      httr2::oauth_flow_client_credentials(
        client = self$.oauth_client,
        scope = self$.scope_str
      )
    },
    #' @description
    #' Add OAuth client credentials authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #'
    #' @return The request object with OAuth client credentials authentication configured
    req_auth = function(req) {
      httr2::req_oauth_client_credentials(
        req = req,
        client = self$.oauth_client,
        scope = self$.scope_str
      )
    }
  )
)
