#' Azure API Session
#'
#' @description
#' An R6 class that provides a session wrapper for Azure API interactions.
#' This class manages an API client instance and provides a higher-level
#' interface for working with Azure APIs.
#'
#' @details
#' The `api_session` class wraps an `api_client` instance to provide session
#' management for Azure API interactions. It simplifies the process of
#' maintaining a persistent connection to an Azure API endpoint with
#' consistent authentication and configuration.
#'
#' @export
#' @examples
#' \dontrun{
#' # Create a session with default credentials
#' session <- api_session$new(
#'   host_url = "https://management.azure.com"
#' )
#'
#' # Create a session with custom credentials and options
#' session <- api_session$new(
#'   host_url = "https://management.azure.com",
#'   credentials = my_credential_function,
#'   timeout = 120,
#'   max_tries = 3
#' )
#' }
api_session <- R6::R6Class(
  "api_session",
  private = list(
    host_url = NULL
  ),
  public = list(
    #' @field .client An instance of the api_client class
    .client = NULL,
    #' @description
    #' Create a new API session instance
    #'
    #' @param host_url A character string specifying the base URL for the API
    #'   (e.g., `"https://management.azure.com"`).
    #' @param credentials A function that adds authentication to requests. If
    #'   `NULL`, uses [default_non_auth()]. The function should accept
    #'   an httr2 request object and return a modified request with authentication.
    #' @param timeout An integer specifying the request timeout in seconds.
    #'   Defaults to `60`.
    #' @param connecttimeout An integer specifying the connection timeout in
    #'   seconds. Defaults to `30`.
    #' @param max_tries An integer specifying the maximum number of retry
    #'   attempts for failed requests. Defaults to `5`.
    #' @param ... Additional arguments (currently unused).
    #'
    #' @return A new `api_session` object
    initialize = function(
      host_url,
      credentials = NULL,
      timeout = 60L,
      connecttimeout = 30L,
      max_tries = 5L,
      ...
    ) {
      if (!missing(host_url)) {
        private$host_url <- host_url
      }

      self$.client <- api_client$new(
        private$host_url,
        credentials = credentials,
        timeout = timeout,
        connecttimeout = connecttimeout,
        max_tries = max_tries
      )
    }
  )
)

#' Create Microsoft Graph API Session
#'
#' @description
#' Creates a new API session configured for Microsoft Graph API with
#' automatic Azure authentication. This is a convenience function that
#' sets up the correct host URL and credentials for accessing Microsoft
#' Graph services.
#'
#' @param version A character string specifying the Microsoft Graph API
#'   version to use. Defaults to `"v1.0"`. Common values are `"v1.0"` for
#'   the stable API and `"beta"` for preview features.
#' @param .chain An optional credential chain object to use for authentication.
#'   If `NULL`, uses the default credential chain. See [get_request_authorizer()]
#'   for details.
#'
#' @return An [api_session] object configured for Microsoft Graph API
#'
#' @details
#' The function automatically configures:
#' - Host URL: `https://graph.microsoft.com/{version}`
#' - Scope: Default Azure Graph scope
#' - Tenant: Default Azure tenant ID
#' - Credentials: Azure request authorizer with the configured scope and tenant
#'
#' @export
#' @examples
#' \dontrun{
#' # Create a session for Microsoft Graph v1.0 API
#' graph <- session_graph()
#' graph$.client$.fetch("me")
#'
#' # Create a session for Microsoft Graph beta API
#' graph_beta <- session_graph(version = "beta")
#'
#' # Use the session to make API calls
#' # users <- graph$.client$.fetch("/users")
#' }
session_graph_api <- function(version = "v1.0", .chain = NULL) {
  credentials <- get_request_authorizer(
    scope = default_azure_scope("azure_graph"),
    tenant_id = default_azure_tenant_id(),
    .chain = .chain
  )

  api_session$new(
    host_url = sprintf("https://graph.microsoft.com/%s", version),
    credentials = credentials
  )
}
