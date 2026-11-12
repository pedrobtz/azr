new_wi_cred <- function() {
  WorkloadIdentityCredential$new(
    tenant_id = "test-tenant",
    client_id = "test-client",
    token_file_path = "/nonexistent/token"
  )
}

wi_inject_token <- function(cred, token) {
  key <- rlang::hash(cred$.scope)
  cred$.__enclos_env__$private$.token_cache[[key]] <- token
}
