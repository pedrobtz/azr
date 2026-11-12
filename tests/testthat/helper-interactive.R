new_non_interactive_cred <- function() {
  DeviceCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id",
    allow_prompt = FALSE,
    use_refresh_token = FALSE
  )
}

inject_token <- function(cred, token, scope = NULL) {
  key <- rlang::hash(scope %||% cred$.scope)
  cred$.__enclos_env__$private$.token_cache[[key]] <- token
}
