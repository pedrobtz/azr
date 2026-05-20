# ManagedIdentityCredential ----
#' Managed identity credential authentication
#'
#' @description
#' Authenticates using an Azure managed identity. Supports both system-assigned
#' and user-assigned managed identities. This credential works when code is
#' running inside an Azure environment that has a managed identity configured
#' (e.g., VMs, App Service, Container Instances, AKS pods).
#'
#' @details
#' Authentication is performed by querying the Azure Instance Metadata Service
#' (IMDS) endpoint at `http://169.254.169.254/metadata/identity/oauth2/token`.
#' No credentials need to be stored — the identity is granted by the Azure
#' platform.
#'
#' To use a **system-assigned** managed identity, leave `client_id` as `NULL`.
#' To use a **user-assigned** managed identity, supply its `client_id`.
#'
#' This credential fails immediately (2-second timeout) when not running inside
#' Azure, so it is safe to include early in a credential chain.
#'
#' @export
#' @examples
#' \dontrun{
#' # System-assigned managed identity (no client_id needed)
#' cred <- ManagedIdentityCredential$new(
#'   scope = "https://management.azure.com/.default"
#' )
#'
#' # User-assigned managed identity
#' cred <- ManagedIdentityCredential$new(
#'   scope = "https://management.azure.com/.default",
#'   client_id = "your-user-assigned-client-id"
#' )
#'
#' token <- cred$get_token()
#' }
ManagedIdentityCredential <- R6::R6Class(
  classname = "ManagedIdentityCredential",
  inherit = Credential,
  public = list(
    #' @field .msi_client_id Client ID for user-assigned managed identity, or
    #'   `NULL` for system-assigned.
    .msi_client_id = NULL,

    #' @description
    #' Create a new managed identity credential
    #'
    #' @param scope A character string specifying the OAuth2 scope. Defaults to
    #'   the Azure Resource Manager scope.
    #' @param client_id A character string specifying the client ID of a
    #'   user-assigned managed identity. Leave `NULL` (the default) to use the
    #'   system-assigned managed identity.
    #'
    #' @return A new `ManagedIdentityCredential` object
    initialize = function(scope = NULL, client_id = NULL) {
      self$.msi_client_id <- client_id
      super$initialize(scope = scope)
      lockBinding(".msi_client_id", self)
    },

    #' @description
    #' Get an access token from the IMDS endpoint
    #'
    #' @details
    #' Returns a valid in-object cached token immediately if one exists.
    #' Otherwise queries the Azure Instance Metadata Service (IMDS) for a new
    #' token.
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function() {
      cache_key <- rlang::hash(list(self$.scope, self$.msi_client_id))
      cached <- private$.token_cache[[cache_key]]
      if (private$token_is_valid(cached)) {
        return(cached)
      }

      resource <- self$.resource
      if (!is.null(resource) && !endsWith(resource, "/")) {
        resource <- paste0(resource, "/")
      }

      token <- mi_fetch_token(
        resource = resource,
        client_id = self$.msi_client_id
      )
      private$.token_cache[[cache_key]] <- token
      token
    },

    #' @description
    #' Add managed identity authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #'
    #' @return The request object with a Bearer token authorization header
    req_auth = function(req) {
      token <- self$get_token()
      httr2::req_auth_bearer_token(req, token$access_token)
    }
  ),
  # private ----
  private = list(
    .token_cache = list(),
    token_is_valid = function(token) {
      if (is.null(token) || !inherits(token, "httr2_token")) {
        return(FALSE)
      }
      !token_has_expired(token)
    }
  )
)


mi_imds_endpoint <- "http://169.254.169.254/metadata/identity/oauth2/token"
mi_imds_api_version <- "2018-02-01"
mi_imds_timeout <- 2L


mi_fetch_token <- function(resource, client_id = NULL) {
  query <- list(`api-version` = mi_imds_api_version, resource = resource)
  if (!is.null(client_id)) {
    query$client_id <- client_id
  }

  resp <- rlang::try_fetch(
    httr2::request(mi_imds_endpoint) |>
      httr2::req_headers(Metadata = "true") |>
      httr2::req_url_query(!!!query) |>
      httr2::req_timeout(mi_imds_timeout) |>
      httr2::req_error(is_error = \(r) FALSE) |>
      httr2::req_perform(),
    error = function(cnd) {
      cli::cli_abort(
        c(
          "Failed to reach the IMDS endpoint.",
          "i" = "Ensure this code is running inside an Azure environment.",
          "x" = conditionMessage(cnd)
        ),
        class = "azr_managed_identity_imds_error",
        call = call("get_token")
      )
    }
  )

  body <- mi_resp_body_json(resp)

  if (!is.null(body$error)) {
    cli::cli_abort(
      c(
        "Managed identity token request failed: {body$error}",
        "x" = body$error_description %||% "No error description provided."
      ),
      class = "azr_managed_identity_token_error",
      call = call("get_token")
    )
  }

  httr2::oauth_token(
    access_token = body$access_token,
    token_type = body$token_type %||% "Bearer",
    expires_in = as.numeric(body$expires_in)
  )
}


mi_resp_body_json <- function(resp) {
  rlang::try_fetch(
    httr2::resp_body_json(resp),
    error = function(cnd) {
      body <- httr2::resp_body_string(resp)
      if (nchar(body) > 200) {
        body <- paste0(substr(body, 1, 200), "...")
      }

      cli::cli_abort(
        c(
          "IMDS returned an invalid JSON response.",
          "i" = "URL: {.url {httr2::resp_url(resp)}}",
          "i" = "Status: {httr2::resp_status(resp)}",
          "x" = conditionMessage(cnd),
          "i" = "Body: {body}"
        ),
        class = "azr_managed_identity_invalid_json_response",
        call = call("get_token")
      )
    }
  )
}
