#' Validate Endpoint Paths
#'
#' @description
#' Validates that endpoint paths (names of the endpoints list) are single strings
#' without spaces and contain only valid URL path characters.
#'
#' @param endpoint_paths A character vector of endpoint path strings to validate
#'
#' @return Invisibly returns `NULL` if validation passes, otherwise throws an error
#'
#' @noRd
validate_endpoint_paths <- function(endpoint_paths) {
  if (length(endpoint_paths) == 0) {
    return(invisible(NULL))
  }

  for (i in seq_along(endpoint_paths)) {
    endpoint_path <- endpoint_paths[i]

    # Check if it's a character string
    if (!is.character(endpoint_path) || length(endpoint_path) != 1) {
      cli::cli_abort(
        "Endpoint path at position {i} must be a single character string"
      )
    }

    # Check if it's not empty
    if (!nzchar(endpoint_path)) {
      cli::cli_abort(
        "Endpoint path at position {i} must not be an empty string"
      )
    }

    # Check for spaces
    if (grepl("\\s", endpoint_path)) {
      cli::cli_abort(
        "Endpoint path at position {i} ({.val {endpoint_path}}) contains spaces"
      )
    }

    # Check for valid URL path characters (alphanumeric, hyphens, underscores, dots, slashes)
    if (!grepl("^[a-zA-Z0-9._/-]+$", endpoint_path)) {
      cli::cli_abort(
        c(
          "Endpoint path at position {i} ({.val {endpoint_path}}) contains invalid characters.",
          "i" = "Only alphanumeric, '.', '_', '-', and '/' are allowed."
        )
      )
    }
  }

  invisible(NULL)
}


#' API Service Base Class
#'
#' @description
#' Base R6 class for creating API service wrappers. This class provides a
#' foundation for building service-specific API clients with authentication,
#' endpoint management, and configuration.
#'
#' @export
api_service <- R6::R6Class(
  classname = "api_service",
  lock_objects = FALSE,
  private = list(
    .chain = NULL,
    .endpoints = NULL,
    .config = NULL
  ),
  public = list(
    #' @field .client An [api_client] instance for making API requests
    .client = NULL,

    #' @description
    #' Create a new API service instance
    #'
    #' @param client An [api_client] instance. If `NULL`, a new client will be created.
    #' @param chain A [credential_chain] instance for authentication. Optional.
    #' @param endpoints A named list where names are endpoint paths (e.g., "v1.0", "beta")
    #'   and values are R6 class objects (not instances) to use for creating resources.
    #'   Defaults to an empty list. If the value is `NULL`, [api_resource] will be used.
    #' @param config A list of configuration options. Defaults to an empty list.
    #'
    #' @return A new `api_service` object
    initialize = function(client = NULL,
                          chain = NULL,
                          endpoints = list(),
                          config = list()) {
      self$.client <- client
      private$.chain <- chain
      private$.config <- config

      # Validate that endpoints is a list
      if (!is.list(endpoints)) {
        cli::cli_abort("{.arg endpoints} must be a list.")
      }

      # Get endpoint paths (names)
      endpoint_paths <- names(endpoints)

      # Validate endpoint paths
      validate_endpoint_paths(endpoint_paths)

      private$.endpoints <- endpoints

      # Loop over endpoints and add api_resources
      if (length(endpoints) > 0) {
        for (i in seq_along(endpoints)) {
          endpoint_path <- endpoint_paths[i]
          resource_class <- endpoints[[i]]

          # If resource_class is NULL, use default api_resource
          if (is.null(resource_class)) {
            resource_class <- api_resource
          }

          # Validate that resource_class is an R6ClassGenerator
          if (!inherits(resource_class, "R6ClassGenerator")) {
            cli::cli_abort(
              "Endpoint {.val {endpoint_path}} must specify an R6 class, not {.cls {class(resource_class)}}."
            )
          }

          # Create resource instance for this endpoint
          resource <- resource_class$new(
            client = self$.client,
            endpoint = endpoint_path
          )

          # Add as a field with the endpoint path name
          self[[endpoint_path]] <- resource

          # Lock the endpoint field to make it read-only
          lockBinding(endpoint_path, self)
        }
      }

      # Lock all fields to make them read-only
      lockBinding(".client", self)
      lockBinding(".chain", private)
      lockBinding(".endpoints", private)
      lockBinding(".config", private)
    },

    #' @description
    #' Print method for the API service
    #'
    #' @param ... Additional arguments (ignored)
    print = function(...) {
      cli::cli_h1("API Service")

      if (!is.null(self$.client)) {
        cli::cli_text("Client: {.cls {class(self$.client)[1]}}")
      } else {
        cli::cli_text("Client: {.emph not set}")
      }

      if (!is.null(private$.chain)) {
        cli::cli_text("Chain: {.cls {class(private$.chain)[1]}}")
      } else {
        cli::cli_text("Chain: {.emph not set}")
      }

      if (length(private$.endpoints) > 0) {
        cli::cli_text("Endpoints: {length(private$.endpoints)}")
      } else {
        cli::cli_text("Endpoints: {.emph none}")
      }

      if (!is.null(private$.config) && length(private$.config) > 0) {
        cli::cli_text("Config: {length(private$.config)} option{?s}")
      } else {
        cli::cli_text("Config: {.emph none}")
      }

      invisible(self)
    }
  )
)
