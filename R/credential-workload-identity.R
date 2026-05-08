# WorkloadIdentityCredential ----
#' Workload Identity credential authentication
#'
#' @description
#' Authenticates using Azure Workload Identity by reading a federated token from
#' a file and exchanging it for an Azure AD access token. This is commonly used
#' in Kubernetes environments (AKS) where a service account token is mounted
#' into the pod.
#'
#' @details
#' The credential implements the OAuth 2.0 client credentials flow with a JWT
#' bearer assertion (`client_assertion`). It reads the federated identity token
#' from a file on each call to `get_token()` so that token rotation by the
#' runtime (e.g., Kubernetes) is automatically picked up.
#'
#' The following environment variables are used when parameters are not provided:
#' - `AZURE_CLIENT_ID`: Client (application) ID of the Azure AD application
#' - `AZURE_TENANT_ID`: Azure AD tenant ID
#' - `AZURE_FEDERATED_TOKEN_FILE`: Path to the file containing the federated token
#'
#' @export
#' @examples
#' # Create credential using environment variables
#' # (requires AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_FEDERATED_TOKEN_FILE)
#' cred <- WorkloadIdentityCredential$new(
#'   scope = "https://management.azure.com/.default"
#' )
#'
#' # Or supply parameters directly
#' cred <- WorkloadIdentityCredential$new(
#'   tenant_id = "your-tenant-id",
#'   client_id = "your-client-id",
#'   token_file_path = "/var/run/secrets/azure/tokens/azure-identity-token",
#'   scope = "https://management.azure.com/.default"
#' )
#'
#' \dontrun{
#' # Get an access token
#' token <- cred$get_token()
#'
#' # Use with httr2 request
#' req <- httr2::request("https://management.azure.com/subscriptions")
#' resp <- httr2::req_perform(cred$req_auth(req))
#' }
WorkloadIdentityCredential <- R6::R6Class(
  classname = "WorkloadIdentityCredential",
  inherit = Credential,
  public = list(
    #' @field .token_file_path Path to the file containing the federated identity token
    .token_file_path = NULL,

    #' @description
    #' Create a new Workload Identity credential
    #'
    #' @param scope A character string specifying the OAuth2 scope. Defaults to
    #'   the Azure Resource Manager scope.
    #' @param tenant_id A character string specifying the Azure AD tenant ID.
    #'   Defaults to the `AZURE_TENANT_ID` environment variable.
    #' @param client_id A character string specifying the client (application) ID.
    #'   Defaults to the `AZURE_CLIENT_ID` environment variable.
    #' @param token_file_path A character string specifying the path to the file
    #'   containing the federated identity token. Defaults to the
    #'   `AZURE_FEDERATED_TOKEN_FILE` environment variable.
    #'
    #' @return A new `WorkloadIdentityCredential` object
    initialize = function(
      scope = NULL,
      tenant_id = Sys.getenv(
        environment_variables$azure_tenant_id,
        unset = NA_character_
      ),
      client_id = Sys.getenv(
        environment_variables$azure_client_id,
        unset = NA_character_
      ),
      token_file_path = default_federated_token_file()
    ) {
      tenant_id <- wi_required_value(
        tenant_id,
        envvar = environment_variables$azure_tenant_id,
        arg = "tenant_id"
      )
      client_id <- wi_required_value(
        client_id,
        envvar = environment_variables$azure_client_id,
        arg = "client_id"
      )
      self$.token_file_path <- token_file_path
      super$initialize(
        scope = scope,
        tenant_id = tenant_id,
        client_id = client_id
      )
      lockBinding(".token_file_path", self)
    },

    #' @description
    #' Validate the credential configuration
    #'
    #' @details
    #' Checks that `token_file_path` is provided and not NA. Calls the parent
    #' class validation method.
    validate = function() {
      super$validate()

      if (
        is.null(self$.token_file_path) || rlang::is_na(self$.token_file_path)
      ) {
        cli::cli_abort(
          c(
            "Argument {.arg token_file_path} cannot be NULL or NA.",
            "i" = "Set the {.envvar AZURE_FEDERATED_TOKEN_FILE} environment variable or pass {.arg token_file_path} directly."
          ),
          class = "azr_workload_identity_missing_token_file"
        )
      }
    },

    #' @description
    #' Get an access token by exchanging the federated token
    #'
    #' @details
    #' Returns a valid in-object cached token immediately if one exists. Otherwise
    #' reads the federated token from the file and exchanges it for a new access
    #' token so that token rotation performed by the runtime is automatically
    #' reflected.
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function() {
      cache_key <- rlang::hash(self$.scope)

      cached <- private$.token_cache[[cache_key]]
      if (private$token_is_valid(cached)) {
        return(cached)
      }

      federated_token <- wi_read_token_file(self$.token_file_path)
      token <- wi_exchange_token(
        federated_token = federated_token,
        client_id = self$.client_id,
        scope = self$.scope_str,
        token_url = self$.token_url
      )
      private$.token_cache[[cache_key]] <- token
      token
    },

    #' @description
    #' Add authentication to an httr2 request
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


wi_required_value <- function(value, envvar, arg) {
  if (is_empty(value)) {
    cli::cli_abort(
      c(
        "Argument {.arg {arg}} cannot be NULL or NA.",
        "i" = "Set the {.envvar {envvar}} environment variable or pass {.arg {arg}} directly."
      ),
      class = "azr_workload_identity_missing_required_value"
    )
  }

  value
}


# Read the federated identity token from a file, trimming whitespace.
wi_read_token_file <- function(path) {
  if (!file.exists(path)) {
    cli::cli_abort(
      c(
        "Federated token file not found: {.path {path}}",
        "i" = "Ensure {.envvar AZURE_FEDERATED_TOKEN_FILE} points to a valid file."
      ),
      class = "azr_workload_identity_file_not_found"
    )
  }

  token <- trimws(paste(readLines(path, warn = FALSE), collapse = ""))

  if (!nzchar(token)) {
    cli::cli_abort(
      c(
        "Federated token file is empty: {.path {path}}",
        "i" = "The file must contain a valid JWT token."
      ),
      class = "azr_workload_identity_empty_token"
    )
  }

  token
}


# Exchange a federated token for an Azure AD access token using the
# OAuth 2.0 client credentials grant with a JWT bearer assertion.
wi_exchange_token <- function(federated_token, client_id, scope, token_url) {
  resp <- rlang::try_fetch(
    httr2::request(token_url) |>
      httr2::req_body_form(
        grant_type = "client_credentials",
        client_id = client_id,
        client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
        client_assertion = federated_token,
        scope = scope
      ) |>
      httr2::req_error(is_error = \(r) FALSE) |>
      httr2::req_perform(),
    error = function(cnd) {
      cli::cli_abort(
        c(
          "Failed to reach the token endpoint.",
          "i" = "URL: {.url {token_url}}",
          "x" = conditionMessage(cnd)
        ),
        class = "azr_workload_identity_exchange_error",
        call = call("get_token")
      )
    }
  )

  body <- wi_resp_body_json(resp)

  if (!is.null(body$error)) {
    cli::cli_abort(
      c(
        "Token exchange failed: {body$error}",
        "x" = body$error_description %||% "No error description provided."
      ),
      class = "azr_workload_identity_token_error",
      call = call("get_token")
    )
  }

  httr2::oauth_token(
    access_token = body$access_token,
    token_type = body$token_type %||% "Bearer",
    expires_in = as.numeric(body$expires_in)
  )
}


wi_resp_body_json <- function(resp) {
  rlang::try_fetch(
    httr2::resp_body_json(resp),
    error = function(cnd) {
      body <- httr2::resp_body_string(resp)
      if (nchar(body) > 200) {
        body <- paste0(substr(body, 1, 200), "...")
      }

      cli::cli_abort(
        c(
          "Token endpoint returned an invalid JSON response.",
          "i" = "URL: {.url {httr2::resp_url(resp)}}",
          "i" = "Status: {httr2::resp_status(resp)}",
          "x" = conditionMessage(cnd),
          "i" = "Body: {body}"
        ),
        class = "azr_workload_identity_invalid_json_response",
        call = call("get_token")
      )
    }
  )
}
