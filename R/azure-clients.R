#' Create a Microsoft Graph API Client
#'
#' @description
#' Creates a configured client for the Microsoft Graph API with authentication
#' and versioned endpoints (v1.0 and beta). This function returns an
#' [api_service] object that provides access to Microsoft Graph resources
#' through versioned endpoints.
#'
#' @details
#' The function creates a Microsoft Graph service using these components:
#'
#' - **[api_client]**: A general-purpose API client configured with the Graph API
#'   host URL (`https://graph.microsoft.com`) and authentication provider.
#'
#' - **[api_graph_resource]**: A specialized resource class that extends [api_resource]
#'   with Microsoft Graph-specific methods. Currently implements:
#'   - `me(select = NULL)`: Fetch the current user's profile. The `select` parameter
#'     accepts a character vector of properties to return (e.g., `c("displayName", "mail")`).
#'
#' - **[api_service]**: A service container that combines the client and resources
#'   with versioned endpoints (v1.0 and beta). The service is locked using
#'   [lockEnvironment()] to prevent modification after creation.
#'
#' @param chain A [credential_chain] instance for authentication. If NULL,
#'   a default credential chain will be created using [get_credential_provider()].
#' @param ... Additional arguments passed to the [api_client] constructor.
#'
#' @return An [api_service] object configured for Microsoft Graph API with
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
# azr_graph_client ----
azr_graph_client <- function(..., chain = NULL) {
  provider <- get_credential_provider(
    scope = default_azure_scope("azure_graph"),
    chain = chain
  )

  client <- api_client$new(
    host_url = "https://graph.microsoft.com",
    provider = provider,
    ...
  )

  service <- api_service$new(
    client = client,
    chain = chain,
    endpoints = list(
      "v1.0" = api_graph_resource,
      "beta" = api_graph_resource
    )
  )

  lockEnvironment(service, bindings = TRUE)

  service
}


#' Microsoft Graph API Resource
#'
#' @description
#' An R6 class that extends [api_resource] to provide specialized methods
#' for the Microsoft Graph API. This class adds convenience methods for
#' common Graph operations.
#'
#' @keywords internal
# api_graph_resource ----
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
      if (!is.null(select)) {
        if (!is.character(select) || length(select) == 0) {
          cli::cli_abort("{.arg select} must be a non-empty character vector.")
        }
        query <- list(`$select` = paste(select, collapse = ","))
      } else {
        query <- NULL
      }

      self$.client$.fetch("me", req_data = query)
    }
  )
)
