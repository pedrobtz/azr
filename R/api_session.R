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
