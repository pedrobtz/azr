new_mi_cred <- function(managed_identity_client_id = NULL) {
  ManagedIdentityCredential$new(
    scope = "https://management.azure.com/.default",
    managed_identity_client_id = managed_identity_client_id
  )
}

mi_inject_token <- function(cred, token) {
  key <- rlang::hash(list(cred$.scope, cred$.msi_client_id))
  cred$.__enclos_env__$private$.token_cache[[key]] <- token
}

# Clears every variable mi_detect_source() reads, then sets the given ones, so
# a test sees the same host whatever machine it runs on.
local_mi_env <- function(..., .env = parent.frame()) {
  vars <- c(
    "IDENTITY_ENDPOINT",
    "IDENTITY_HEADER",
    "IDENTITY_SERVER_THUMBPRINT",
    "IMDS_ENDPOINT",
    "MSI_ENDPOINT",
    "MSI_SECRET"
  )
  values <- rlang::set_names(rep(NA_character_, length(vars)), vars)
  set <- c(...)
  values[names(set)] <- set
  withr::local_envvar(values, .local_envir = .env)
}

mi_json_response <- function(body, status = 200L, headers = list()) {
  httr2::response(
    status_code = status,
    headers = c(list(`content-type` = "application/json"), headers),
    body = charToRaw(jsonlite::toJSON(body, auto_unbox = TRUE))
  )
}
