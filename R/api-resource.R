#' Azure API Resource
#'
#' @description
#' An R6 class that wraps an `api_client` and adds an additional path segment
#' (like "beta" or "v1.0") to all requests. This is useful for APIs that version
#' their endpoints or have different API surfaces under different paths.
#'
#' @details
#' The `api_resource` class creates a modified base request by appending an
#' endpoint path to the client's base request. All subsequent API calls through
#' this resource will automatically include this path prefix.
#'
#' @export
#' @examples
#' \dontrun{
#' # Create a client
#' client <- api_client$new(
#'   host_url = "https://graph.microsoft.com"
#' )
#'
#' # Create a resource with v1.0 API endpoint
#' resource_v1 <- api_resource$new(
#'   client = client,
#'   endpoint = "v1.0"
#' )
#'
#' # Create a resource with beta API endpoint
#' resource_beta <- api_resource$new(
#'   client = client,
#'   endpoint = "beta"
#' )
#'
#' # Make requests - the endpoint is automatically prepended
#' response <- resource_v1$.fetch(
#'   path = "/me",
#'   req_method = "get"
#' )
#' }
api_resource <- R6::R6Class(
  classname = "api_resource",
  cloneable = FALSE,
  # > private ----
  private = list(
    #' @field endpoint The API endpoint path segment (e.g., "v1.0", "beta")
    endpoint = NULL
  ),
  # > public ----
  public = list(
    #' @field .client The cloned api_client instance with modified base_req
    .client = NULL,
    #' @description
    #' Create a new API resource instance
    #'
    #' @param client An `api_client` object that provides the base HTTP client
    #'   functionality. This will be cloned to avoid modifying the original.
    #' @param endpoint A character string specifying the API endpoint or path
    #'   segment to append (e.g., `"v1.0"`, `"beta"`).
    #'
    #' @return A new `api_resource` object
    initialize = function(client, endpoint) {
      if (is.null(client)) {
        cli::cli_abort("{.arg client} must not be {.val NULL}.")
      }
      if (!R6::is.R6(client)) {
        cli::cli_abort("{.arg client} must be an R6 object.")
      }
      if (!inherits(client, "api_client")) {
        cli::cli_abort("{.arg client} must be an {.cls api_client} object.")
      }

      # If endpoint is already set, do nothing (ignore the argument)
      if (!is.null(private$endpoint)) {
        # Do nothing - keep existing endpoint
      } else {
        if (is.null(endpoint)) {
          cli::cli_abort("{.arg endpoint} must not be {.val NULL}.")
        }
        if (!is.character(endpoint)) {
          cli::cli_abort("{.arg endpoint} must be a character string.")
        }
        if (length(endpoint) != 1L) {
          cli::cli_abort(
            "{.arg endpoint} must be a single character string, not length {length(endpoint)}."
          )
        }
        if (!nzchar(endpoint)) {
          cli::cli_abort("{.arg endpoint} must not be an empty string.")
        }

        private$endpoint <- endpoint
      }

      # Clone the client and modify its base_req to include the endpoint path
      self$.client <- client$clone()
      self$.client$.base_req <- self$.client$.base_req |>
        httr2::req_url_path_append(private$endpoint)

      # Lock all fields to prevent modification
      lockBinding(".client", self)
      lockBinding("endpoint", private)
    }
  )
)
