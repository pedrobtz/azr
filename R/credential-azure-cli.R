#' Azure CLI credential authentication
#'
#' @description
#' Authenticates using the Azure CLI (`az`) command-line tool. This credential
#' requires the Azure CLI to be installed and the user to be logged in via
#' `az login`.
#'
#' @details
#' The credential uses the `az account get-access-token` command to retrieve
#' access tokens. It will use the currently active Azure CLI account and
#' subscription unless a specific tenant is specified.
#'
#' @export
#' @examples
#' # Create credential with default settings
#' cred <- AzureCLICredential$new()
#'
#' # Create credential with specific scope and tenant
#' cred <- AzureCLICredential$new(
#'   scope = "https://management.azure.com/.default",
#'   tenant_id = "your-tenant-id"
#' )
#'
#' # To get a token or authenticate a request it is required that
#' # 'az login' is successfully executed, otherwise it will return an error.
#' \dontrun{
#' # Get an access token
#' token <- cred$get_token()
#'
#' # Use with httr2 request
#' req <- httr2::request("https://management.azure.com/subscriptions")
#' resp <- httr2::req_perform(cred$req_auth(req))
#' }
AzureCLICredential <- R6::R6Class(
  classname = "AzureCLICredential",
  inherit = Credential,
  public = list(
    #' @field .process_timeout Timeout in seconds for Azure CLI command execution
    .process_timeout = 10,

    #' @description
    #' Create a new Azure CLI credential
    #'
    #' @param scope A character string specifying the OAuth2 scope. Defaults to
    #'   `NULL`, which uses the scope set during initialization.
    #' @param tenant_id A character string specifying the Azure Active Directory
    #'   tenant ID. Defaults to `NULL`, which uses the default tenant from Azure CLI.
    #' @param process_timeout A numeric value specifying the timeout in seconds
    #'   for the Azure CLI process. Defaults to `10`.
    #'
    #' @return A new `AzureCLICredential` object
    initialize = function(scope = NULL,
                          tenant_id = NULL,
                          process_timeout = NULL) {
      super$initialize(scope = scope, tenant_id = tenant_id)
      self$.process_timeout <- process_timeout %||% self$.process_timeout
    },
    #' @description
    #' Get an access token from Azure CLI
    #'
    #' @param scope A character string specifying the OAuth2 scope. If `NULL`,
    #'   uses the scope specified during initialization.
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function(scope = NULL) {
      rlang::try_fetch(.az_cli_run(
        scope = scope %||% self$.scope,
        tenant_id = self$.tenant_id,
        timeout = self$.process_timeout
      ), error = function(cnd) rlang::abort(cnd$message, call = call("get_token")))
    },
    #' @description
    #' Add authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #' @param scope A character string specifying the OAuth2 scope. If `NULL`,
    #'   uses the scope specified during initialization.
    #'
    #' @return The request object with authentication header added
    req_auth = function(req, scope = NULL) {
      token <- self$get_token(scope)
      httr2::req_auth_bearer_token(req, token$access_token)
    }
  )
)


.az_cli_run <- function(scope, tenant_id = NULL, timeout = 10L) {
  args <- c("account", "get-access-token", "--output", "json")
  az_path <- Sys.which("az")

  if (!nzchar(az_path)) {
    rlang::abort("Azure CLI not found on path")
  }

  validate_scope(scope)
  args <- append(args, c("--scope", scope))

  if (!is.null(tenant_id)) {
    validate_tenant_id(tenant_id)
    args <- append(args, c("--tenant", tenant_id))
  }

  output <- suppressWarnings(system2(
    command = az_path,
    args = args,
    stdout = TRUE,
    stderr = TRUE,
    timeout = timeout
  ))
  attr_output <- attributes(output)

  if (!is.null(attr_output) && attr_output$status == 1L) {
    cli::cli_abort(output)
  }

  token <- jsonlite::fromJSON(output)

  httr2::oauth_token(
    access_token = token$accessToken,
    token_type = token$tokenType,
    expires_in = token$expires_on
  )
}
