# ManagedIdentityCredential ----
#' Managed identity credential authentication
#'
#' @description
#' Authenticates using an Azure managed identity. Supports both system-assigned
#' and user-assigned managed identities. This credential works when code is
#' running inside an Azure environment that has a managed identity configured.
#' No credentials need to be stored — the identity is granted by the Azure
#' platform.
#'
#' @details
#' The token endpoint depends on the host, which the credential detects from
#' environment variables the platform sets, in the same order as the Azure
#' SDKs:
#'
#' | Source | Hosts | Detected by |
#' |--------|-------|-------------|
#' | `"app_service"` | App Service, Azure Functions, Container Apps | `IDENTITY_ENDPOINT` and `IDENTITY_HEADER` |
#' | `"azure_arc"` | Azure Arc-enabled servers | `IDENTITY_ENDPOINT` and `IMDS_ENDPOINT` |
#' | `"app_service_2017"` | App Service (legacy API) | `MSI_ENDPOINT` and `MSI_SECRET` |
#' | `"cloud_shell"` | Azure Cloud Shell | `MSI_ENDPOINT` alone |
#' | `"imds"` | VMs, VM scale sets, Container Instances, AKS nodes | none of the above |
#'
#' The Instance Metadata Service (IMDS) at
#' `http://169.254.169.254/metadata/identity/oauth2/token` is the fallback.
#' Service Fabric (`IDENTITY_SERVER_THUMBPRINT` alongside `IDENTITY_ENDPOINT`
#' and `IDENTITY_HEADER`) is detected but not supported: [get_token()] fails
#' with a classed error and the credential chain moves on. Azure Arc and Cloud
#' Shell support only the system-assigned identity.
#'
#' The detected source is stored in the `.msi_source` field and shown by
#' `print()` and in verbose credential-chain output.
#'
#' To use a **system-assigned** managed identity, leave
#' `managed_identity_client_id` as `NULL`. To use a **user-assigned** managed
#' identity, supply its client ID as `managed_identity_client_id`, or set the
#' `managed_identity_client_id` option (`options(azr.managed_identity_client_id
#' = ...)` or `AZR_MANAGED_IDENTITY_CLIENT_ID`) so the credential chain in
#' [get_token()] picks it up.
#'
#' A user-assigned identity is a different principal from an app registration,
#' so the `client_id` given to [get_token()] and friends is not forwarded to
#' this credential: it identifies the app registration that
#' [ClientSecretCredential] and the interactive credentials authenticate as.
#'
#' Against IMDS this credential fails fast (2-second timeout) when not running
#' inside Azure, so it is safe to include early in a credential chain.
#'
#' @export
#' @examples
#' \dontrun{
#' # System-assigned managed identity
#' cred <- ManagedIdentityCredential$new(
#'   scope = "https://management.azure.com/.default"
#' )
#'
#' # User-assigned managed identity
#' cred <- ManagedIdentityCredential$new(
#'   scope = "https://management.azure.com/.default",
#'   managed_identity_client_id = "your-user-assigned-client-id"
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

    #' @field .msi_source Token source detected from the environment: one of
    #'   `"app_service"`, `"azure_arc"`, `"app_service_2017"`, `"cloud_shell"`,
    #'   `"service_fabric"` or `"imds"`.
    .msi_source = NULL,

    #' @description
    #' Create a new managed identity credential
    #'
    #' @param scope A character string specifying the OAuth2 scope. Defaults to
    #'   the Azure Resource Manager scope.
    #' @param managed_identity_client_id A character string specifying the
    #'   client ID of a user-assigned managed identity. Defaults to the
    #'   `managed_identity_client_id` option; when that is unset, `NULL` selects
    #'   the system-assigned managed identity.
    #' @param ... Accepts the deprecated `client_id` argument, an alias for
    #'   `managed_identity_client_id`. It is taken through `...` so that the
    #'   credential chain, which forwards only named constructor arguments,
    #'   never passes an app registration's client ID here.
    #'
    #' @return A new `ManagedIdentityCredential` object
    initialize = function(
      scope = NULL,
      managed_identity_client_id = opts$get("managed_identity_client_id"),
      ...
    ) {
      managed_identity_client_id <- mi_take_deprecated_client_id(
        managed_identity_client_id,
        ...
      )
      if (!is.null(managed_identity_client_id)) {
        validate_required_string(
          managed_identity_client_id,
          "managed_identity_client_id"
        )
      }
      self$.msi_client_id <- managed_identity_client_id
      self$.msi_source <- mi_detect_source()
      super$initialize(scope = scope)
      lockBinding(".msi_client_id", self)
      lockBinding(".msi_source", self)
    },

    #' @description
    #' Get an access token from the managed identity endpoint
    #'
    #' @details
    #' Returns a valid in-object cached token immediately if one exists.
    #' Otherwise requests a new token from the endpoint of the detected
    #' source (see Details above).
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
        client_id = self$.msi_client_id,
        source = self$.msi_source
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


# `client_id` is read from `...` rather than declared, because new_instance()
# forwards every context name that matches a formal, and the chain's
# `client_id` names an app registration, not a managed identity.
mi_take_deprecated_client_id <- function(managed_identity_client_id, ...) {
  dots <- list(...)
  unknown <- setdiff(names(dots), "client_id")
  if (length(unknown) > 0L || (length(dots) > 0L && is.null(names(dots)))) {
    cli::cli_abort(
      "Unused argument{?s} to {.fn ManagedIdentityCredential$new}: {.arg {unknown}}.",
      class = "azr_managed_identity_unused_argument",
      call = call("initialize")
    )
  }
  if (!"client_id" %in% names(dots)) {
    return(managed_identity_client_id)
  }
  deprecated_arg(
    "client_id",
    "managed_identity_client_id",
    "ManagedIdentityCredential$new"
  )
  dots$client_id
}


mi_imds_endpoint <- "http://169.254.169.254/metadata/identity/oauth2/token"
mi_imds_api_version <- "2018-02-01"
mi_imds_timeout <- 2L
# Endpoints found through environment variables are local to a host that is
# known to be Azure, so they get longer than IMDS's fail-fast probe.
mi_local_timeout <- 10L
mi_arc_max_key_size <- 4096L

mi_source_labels <- c(
  imds = "IMDS",
  app_service = "App Service",
  app_service_2017 = "App Service (2017-09-01)",
  cloud_shell = "Cloud Shell",
  azure_arc = "Azure Arc",
  service_fabric = "Service Fabric"
)


# Follows the Azure SDKs' order: the more specific variable combinations win,
# and IMDS is the fallback when the host sets none of them.
mi_detect_source <- function() {
  has <- function(x) nzchar(Sys.getenv(x))

  if (has("IDENTITY_ENDPOINT")) {
    if (has("IDENTITY_HEADER")) {
      if (has("IDENTITY_SERVER_THUMBPRINT")) {
        return("service_fabric")
      }
      return("app_service")
    }
    if (has("IMDS_ENDPOINT")) {
      return("azure_arc")
    }
  }

  if (has("MSI_ENDPOINT")) {
    if (has("MSI_SECRET")) {
      return("app_service_2017")
    }
    return("cloud_shell")
  }

  "imds"
}


mi_fetch_token <- function(resource, client_id = NULL, source = "imds") {
  mi_check_source(source, client_id)

  req <- mi_token_request(source, resource = resource, client_id = client_id)
  resp <- mi_perform(req, source)

  # Arc answers the first request with a challenge naming a key file that only
  # a local administrator or the agent's group can read; reading it proves the
  # caller runs on the machine.
  if (source == "azure_arc" && httr2::resp_status(resp) == 401L) {
    key <- mi_arc_read_key(resp)
    req <- httr2::req_headers(
      req,
      Authorization = paste("Basic", key),
      .redact = "Authorization"
    )
    resp <- mi_perform(req, source)
  }

  body <- mi_resp_body_json(resp)

  if (!is.null(body$error)) {
    error_code <- if (is.list(body$error)) body$error$code else body$error
    error_desc <- body$error_description %||%
      (if (is.list(body$error)) body$error$message) %||%
      "No error description provided."
    cli::cli_abort(
      c(
        "Managed identity token request failed: {error_code}",
        "x" = error_desc
      ),
      class = "azr_managed_identity_token_error",
      call = call("get_token")
    )
  }

  if (is.null(body$access_token)) {
    cli::cli_abort(
      c(
        "Managed identity endpoint returned no access token.",
        "i" = "Source: {mi_source_labels[[source]]}",
        "i" = "Status: {httr2::resp_status(resp)}"
      ),
      class = "azr_managed_identity_token_error",
      call = call("get_token")
    )
  }

  httr2::oauth_token(
    access_token = body$access_token,
    token_type = body$token_type %||% "Bearer",
    expires_in = mi_expires_in(body)
  )
}


mi_check_source <- function(source, client_id) {
  if (source == "service_fabric") {
    cli::cli_abort(
      c(
        "Service Fabric managed identity is not supported.",
        "i" = "The endpoint requires pinning its certificate by
          {.envvar IDENTITY_SERVER_THUMBPRINT}, which is not implemented."
      ),
      class = "azr_managed_identity_unsupported_source",
      call = call("get_token")
    )
  }

  if (!is.null(client_id) && source %in% c("azure_arc", "cloud_shell")) {
    cli::cli_abort(
      c(
        "{mi_source_labels[[source]]} supports only the system-assigned managed identity.",
        "i" = "Unset {.arg managed_identity_client_id} to use it."
      ),
      class = "azr_managed_identity_unsupported_user_assigned",
      call = call("get_token")
    )
  }

  invisible(source)
}


mi_token_request <- function(source, resource, client_id = NULL) {
  switch(
    source,
    imds = httr2::request(mi_imds_endpoint) |>
      httr2::req_headers(Metadata = "true") |>
      httr2::req_url_query(
        `api-version` = mi_imds_api_version,
        resource = resource,
        client_id = client_id
      ) |>
      httr2::req_timeout(mi_imds_timeout),
    app_service = httr2::request(Sys.getenv("IDENTITY_ENDPOINT")) |>
      httr2::req_headers(
        `X-IDENTITY-HEADER` = Sys.getenv("IDENTITY_HEADER"),
        .redact = "X-IDENTITY-HEADER"
      ) |>
      httr2::req_url_query(
        `api-version` = "2019-08-01",
        resource = resource,
        client_id = client_id
      ),
    app_service_2017 = httr2::request(Sys.getenv("MSI_ENDPOINT")) |>
      httr2::req_headers(
        secret = Sys.getenv("MSI_SECRET"),
        .redact = "secret"
      ) |>
      httr2::req_url_query(
        `api-version` = "2017-09-01",
        resource = resource,
        clientid = client_id
      ),
    cloud_shell = httr2::request(Sys.getenv("MSI_ENDPOINT")) |>
      httr2::req_headers(Metadata = "true") |>
      httr2::req_body_form(resource = resource),
    azure_arc = httr2::request(Sys.getenv("IDENTITY_ENDPOINT")) |>
      httr2::req_headers(Metadata = "true") |>
      httr2::req_url_query(`api-version` = "2020-06-01", resource = resource),
    cli::cli_abort("Unknown managed identity source {.val {source}}.")
  ) |>
    mi_req_defaults(source)
}


mi_req_defaults <- function(req, source) {
  req <- httr2::req_error(req, is_error = \(r) FALSE)
  if (source == "imds") {
    return(req)
  }
  httr2::req_timeout(req, mi_local_timeout)
}


mi_perform <- function(req, source) {
  rlang::try_fetch(
    httr2::req_perform(req),
    error = function(cnd) {
      if (source == "imds") {
        msg <- "Failed to reach the IMDS endpoint."
        hint <- "Ensure this code is running inside an Azure environment."
        class <- c(
          "azr_managed_identity_imds_error",
          "azr_managed_identity_endpoint_error"
        )
      } else {
        msg <- "Failed to reach the {mi_source_labels[[source]]} managed identity endpoint."
        hint <- "The endpoint comes from environment variables the host sets."
        class <- "azr_managed_identity_endpoint_error"
      }
      cli::cli_abort(
        c(msg, "i" = hint, "x" = conditionMessage(cnd)),
        class = class,
        call = call("get_token")
      )
    }
  )
}


mi_arc_read_key <- function(resp) {
  header <- httr2::resp_header(resp, "WWW-Authenticate") %||% ""
  path <- sub("^.*Basic realm=", "", header)

  arc_abort <- function(problem) {
    cli::cli_abort(
      c("Azure Arc managed identity challenge failed.", "x" = problem),
      class = "azr_managed_identity_arc_error",
      call = call("get_token")
    )
  }

  if (!nzchar(header) || identical(path, header) || !nzchar(path)) {
    arc_abort("The response carried no {.field WWW-Authenticate} realm.")
  }

  # The key file must sit in the agent's token directory: anything else could
  # make this credential read an arbitrary file and send it as a header.
  key_dir <- mi_arc_key_dir()
  if (is.null(key_dir)) {
    arc_abort("Azure Arc is supported only on Linux and Windows.")
  }
  real_dir <- normalizePath(key_dir, winslash = "/", mustWork = FALSE)
  real_path <- normalizePath(path, winslash = "/", mustWork = FALSE)
  if (!identical(dirname(real_path), real_dir)) {
    arc_abort("Key file {.path {path}} is outside {.path {key_dir}}.")
  }
  if (!grepl("\\.key$", real_path, ignore.case = TRUE)) {
    arc_abort("Key file {.path {path}} does not have a {.val .key} extension.")
  }
  if (!file.exists(real_path)) {
    arc_abort("Key file {.path {path}} does not exist.")
  }
  if (file.size(real_path) > mi_arc_max_key_size) {
    arc_abort(
      "Key file {.path {path}} is larger than {mi_arc_max_key_size} bytes."
    )
  }

  readChar(real_path, file.size(real_path), useBytes = TRUE)
}


mi_arc_key_dir <- function() {
  sysname <- Sys.info()[["sysname"]]
  if (identical(sysname, "Windows")) {
    return(file.path(
      Sys.getenv("ProgramData"),
      "AzureConnectedMachineAgent",
      "Tokens"
    ))
  }
  if (identical(sysname, "Linux")) {
    return("/var/opt/azcmagent/tokens")
  }
  NULL
}


# IMDS returns `expires_in`; the 2019-08-01 App Service API returns
# `expires_on` as epoch seconds; the 2017-09-01 API returns `expires_on` as a
# date such as "09/14/2017 00:00:00 PM +00:00". Unparseable expiry leaves the
# token without one, which token_has_expired() treats as never expiring, so a
# conservative hour is assumed instead.
mi_expires_in <- function(body, now = Sys.time()) {
  if (!is.null(body$expires_in)) {
    return(floor(as.numeric(body$expires_in)))
  }

  expires_on <- body$expires_on
  if (is.null(expires_on)) {
    return(3600)
  }

  epoch <- suppressWarnings(as.numeric(expires_on))
  if (is.na(epoch)) {
    epoch <- mi_parse_expires_on(expires_on)
  }
  if (is.na(epoch)) {
    return(3600)
  }

  max(floor(epoch - as.numeric(now)), 0)
}


# strptime() ignores trailing input, so the 12-hour format has to be chosen
# up front: "%H" would read "01:00:00 PM" as one in the morning. Some
# responses pair a 24-hour time with a meaningless "PM", which "%I" rejects,
# hence the 24-hour retry.
mi_parse_expires_on <- function(x) {
  x <- sub(" \\+00:00$", "", x)
  fmts <- "%m/%d/%Y %H:%M:%S"
  if (grepl("(AM|PM)$", x, ignore.case = TRUE)) {
    fmts <- c("%m/%d/%Y %I:%M:%S %p", fmts)
  }
  for (fmt in fmts) {
    t <- as.POSIXct(x, format = fmt, tz = "UTC")
    if (!is.na(t)) {
      return(as.numeric(t))
    }
  }
  NA_real_
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
          "Managed identity endpoint returned an invalid JSON response.",
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
