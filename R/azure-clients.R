#' Microsoft Graph API Client
#'
#' @description
#' An R6 class that extends [api_client] with Microsoft Graph-specific defaults.
#' This client is preconfigured with the Graph API host URL and scope.
#'
#' @keywords internal
api_graph_client <- R6::R6Class(
  classname = "api_graph_client",
  inherit = api_client,
  public = list(
    #' @description
    #' Create a new Microsoft Graph API client instance
    #'
    #' @param provider A credential provider for authentication. If NULL,
    #'   will be passed to [api_client].
    #' @param host_url The Microsoft Graph API base URL. Defaults to
    #'   "https://graph.microsoft.com".
    #' @param ... Additional arguments passed to [api_client] constructor.
    #'
    #' @return A new `api_graph_client` object
    initialize = function(
      provider = NULL,
      host_url = "https://graph.microsoft.com",
      ...
    ) {
      super$initialize(
        host_url = host_url,
        provider = provider,
        ...
      )
    }
  )
)


#' Microsoft Graph API Resource
#'
#' @description
#' An R6 class that extends [api_resource] to provide specialized methods
#' for the Microsoft Graph API. This class adds convenience methods for
#' common Graph operations.
#'
#' @keywords internal
api_graph_resource <- R6::R6Class(
  classname = "api_graph_resource",
  inherit = api_resource,
  public = list(
    #' @description
    #' Fetch the current user's profile
    #'
    #' @param select A character vector of properties to select (e.g., c("displayName", "mail")).
    #'   If NULL, all properties are returned.
    #'
    #' @return The response from the /me endpoint
    me = function(select = NULL) {
      # Add select parameter if provided
      if (!is.null(select)) {
        if (!is.character(select) || length(select) == 0) {
          cli::cli_abort("{.arg select} must be a non-empty character vector.")
        }
        query <- list(`$select` = paste(select, collapse = ","))
      } else {
        query <- NULL
      }

      # Perform the request
      self$.client$.fetch("me", req_data = query)
    }
  )
)


#' Microsoft Graph API Service
#'
#' @description
#' An R6 class that extends [api_service] with Microsoft Graph-specific configuration.
#' This service is preconfigured with Graph API client and endpoints (v1.0 and beta).
#'
#' @keywords internal
api_graph_service <- R6::R6Class(
  classname = "api_graph_service",
  lock_objects = FALSE,
  inherit = api_service,
  public = list(
    #' @description
    #' Create a new Microsoft Graph API service instance
    #'
    #' @param chain A [credential_chain] instance for authentication. If NULL,
    #'   a default credential chain will be created.
    #' @param ... Additional arguments passed to [api_graph_client] constructor.
    #'
    #' @return A new `api_graph_service` object
    initialize = function(chain = NULL, ...) {
      # Get the credential provider from the chain
      provider <- get_credential_provider(
        scope = default_azure_scope("azure_graph"),
        chain = chain
      )

      # Create the Graph API client with the credential provider
      client <- api_graph_client$new(
        provider = provider,
        ...
      )

      # Call parent initialize with client and Graph-specific endpoints
      super$initialize(
        client = client,
        chain = chain,
        endpoints = list(
          "v1.0" = api_graph_resource,
          "beta" = api_graph_resource
        )
      )
    }
  )
)


#' Create a Microsoft Graph API Client
#'
#' @description
#' Creates a configured client for the Microsoft Graph API with authentication
#' and versioned endpoints (v1.0 and beta). This function returns an
#' [api_graph_service] object that provides access to Microsoft Graph resources
#' through versioned endpoints.
#'
#' @details
#' The returned service object is built using three internal R6 classes:
#'
#' ## api_graph_client
#' An R6 class extending [api_client] with Microsoft Graph-specific defaults.
#' Preconfigured with the Graph API host URL (`https://graph.microsoft.com`).
#'
#' ## api_graph_resource
#' An R6 class extending [api_resource] that provides specialized methods for
#' the Microsoft Graph API. Currently implements:
#' - `me(select = NULL)`: Fetch the current user's profile. The `select` parameter
#'   accepts a character vector of properties to return (e.g., `c("displayName", "mail")`).
#'
#' ## api_graph_service
#' An R6 class extending [api_service] that combines the client and resources
#' into a cohesive service with versioned endpoints (v1.0 and beta). Handles
#' credential provider initialization using [get_credential_provider()].
#'
#' @param chain A [credential_chain] instance for authentication. If NULL,
#'   a default credential chain will be created using [get_credential_provider()].
#' @param ... Additional arguments passed to the internal [api_graph_client] constructor.
#'
#' @return An [api_graph_service] object configured for Microsoft Graph API with
#'   v1.0 and beta endpoints. The object is locked using [lockEnvironment()] to
#'   prevent modification after creation. Access endpoints via `$v1.0` or `$beta`.
#'
#' @export
#' @examples
#' \dontrun{
#' # Create a Graph API client with default credentials
#' graph <- azr_graph_client()
#'
#' # Fetch current user profile from v1.0 endpoint
#' me <- graph$v1.0$me()
#'
#' # Fetch specific properties using OData $select
#' me <- graph$v1.0$me(select = c("displayName", "mail", "userPrincipalName"))
#'
#' # Use beta endpoint for preview features
#' me_beta <- graph$beta$me(select = c("displayName", "mail"))
#'
#' # Create with a custom credential chain
#' custom_chain <- credential_chain(
#'   AzureCLICredential$new(scope = "https://graph.microsoft.com/.default")
#' )
#' graph <- azr_graph_client(chain = custom_chain)
#' }
azr_graph_client <- function(chain = NULL, ...) {
  service <- api_graph_service$new(chain = chain, ...)

  # Lock object with lockEnvironment
  lockEnvironment(service, bindings = TRUE)

  service
}
