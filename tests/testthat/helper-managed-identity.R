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
