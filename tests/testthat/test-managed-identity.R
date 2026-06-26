new_mi_cred <- function(client_id = NULL) {
  ManagedIdentityCredential$new(
    scope = "https://management.azure.com/.default",
    client_id = client_id
  )
}

mi_inject_token <- function(cred, token) {
  key <- rlang::hash(list(cred$.scope, cred$.msi_client_id))
  cred$.__enclos_env__$private$.token_cache[[key]] <- token
}

# Construction ----

test_that("constructs with system-assigned identity (NULL client_id)", {
  cred <- new_mi_cred()
  expect_s3_class(cred, "ManagedIdentityCredential")
  expect_null(cred$.msi_client_id)
})

test_that("constructs with user-assigned identity (explicit client_id)", {
  cred <- new_mi_cred(client_id = "my-user-assigned-id")
  expect_equal(cred$.msi_client_id, "my-user-assigned-id")
})

test_that(".msi_client_id is locked after initialize", {
  cred <- new_mi_cred()
  expect_error(
    cred$.msi_client_id <- "changed",
    class = "simpleError"
  )
})

test_that("resource gets trailing slash appended", {
  cred <- new_mi_cred()
  expect_true(endsWith(
    paste0(cred$.resource, "/"),
    "/"
  ))
})

# Token caching ----

test_that("get_token returns valid cached token without calling IMDS", {
  cred <- new_mi_cred()
  token <- httr2::oauth_token(
    access_token = "cached_mi_token",
    expires_in = 3600
  )
  mi_inject_token(cred, token)

  result <- cred$get_token()

  expect_identical(result$access_token, "cached_mi_token")
})

test_that("get_token calls IMDS when cache is empty", {
  cred <- new_mi_cred()
  fresh <- httr2::oauth_token(access_token = "fresh_token", expires_in = 3600)

  local_mocked_bindings(
    mi_fetch_token = function(...) fresh
  )

  result <- cred$get_token()
  expect_identical(result$access_token, "fresh_token")
})

test_that("get_token calls IMDS when cached token is expired", {
  cred <- new_mi_cred()
  expired <- httr2::oauth_token(access_token = "old_token", expires_in = 3600)
  expired$expires_at <- Sys.time() - 3600
  mi_inject_token(cred, expired)
  fresh <- httr2::oauth_token(access_token = "new_token", expires_in = 3600)

  local_mocked_bindings(
    mi_fetch_token = function(...) fresh
  )

  result <- cred$get_token()
  expect_identical(result$access_token, "new_token")
})

test_that("get_token stores fetched token in cache", {
  cred <- new_mi_cred()
  fresh <- httr2::oauth_token(access_token = "stored_token", expires_in = 3600)

  local_mocked_bindings(
    mi_fetch_token = function(...) fresh
  )

  cred$get_token()

  key <- rlang::hash(list(cred$.scope, cred$.msi_client_id))
  cached <- cred$.__enclos_env__$private$.token_cache[[key]]
  expect_identical(cached$access_token, "stored_token")
})

test_that("system and user-assigned identities use separate cache keys", {
  cred_sys <- new_mi_cred()
  cred_usr <- new_mi_cred(client_id = "user-id")

  sys_token <- httr2::oauth_token(access_token = "sys_token", expires_in = 3600)
  usr_token <- httr2::oauth_token(access_token = "usr_token", expires_in = 3600)

  mi_inject_token(cred_sys, sys_token)
  mi_inject_token(cred_usr, usr_token)

  expect_identical(cred_sys$get_token()$access_token, "sys_token")
  expect_identical(cred_usr$get_token()$access_token, "usr_token")
})

# mi_fetch_token ----

test_that("mi_fetch_token errors when IMDS is unreachable", {
  local_mocked_bindings(
    req_perform = function(...) stop("connection refused"),
    .package = "httr2"
  )

  expect_error(
    mi_fetch_token(resource = "https://management.azure.com/"),
    class = "azr_managed_identity_imds_error"
  )
})

test_that("mi_fetch_token errors on IMDS error response", {
  resp_body <- list(
    error = "invalid_request",
    error_description = "Identity not found"
  )

  local_mocked_bindings(
    req_perform = function(...) structure(list(), class = "httr2_response"),
    .package = "httr2"
  )
  local_mocked_bindings(mi_resp_body_json = function(...) resp_body)

  expect_error(
    mi_fetch_token(resource = "https://management.azure.com/"),
    class = "azr_managed_identity_token_error"
  )
})

test_that("mi_fetch_token returns oauth_token on success", {
  resp_body <- list(
    access_token = "imds_access_token",
    token_type = "Bearer",
    expires_in = "3600"
  )

  local_mocked_bindings(
    req_perform = function(...) structure(list(), class = "httr2_response"),
    .package = "httr2"
  )
  local_mocked_bindings(mi_resp_body_json = function(...) resp_body)

  token <- mi_fetch_token(resource = "https://management.azure.com/")

  expect_s3_class(token, "httr2_token")
  expect_identical(token$access_token, "imds_access_token")
})

# mi_resp_body_json ----

test_that("mi_resp_body_json wraps invalid JSON responses", {
  resp <- httr2::response(
    status_code = 502,
    url = "http://169.254.169.254/metadata/identity/oauth2/token",
    headers = list("content-type" = "text/html"),
    body = charToRaw("<html>bad gateway</html>")
  )

  expect_error(
    mi_resp_body_json(resp),
    class = "azr_managed_identity_invalid_json_response"
  )
})

test_that("mi_resp_body_json parses valid token JSON responses", {
  resp <- httr2::response(
    headers = list("content-type" = "application/json"),
    body = charToRaw('{"access_token":"abc","expires_in":3600}')
  )

  body <- mi_resp_body_json(resp)

  expect_equal(body$access_token, "abc")
  expect_equal(body$expires_in, 3600)
})

# default_credential_chain ----

test_that("default_credential_chain includes ManagedIdentityCredential", {
  chain <- default_credential_chain()
  nms <- names(chain)
  expect_true("managed_identity" %in% nms)
})

test_that("default_credential_chain includes WorkloadIdentityCredential", {
  chain <- default_credential_chain()
  nms <- names(chain)
  expect_true("workload_identity" %in% nms)
})

test_that("default_credential_chain orders azure_cli before interactive credentials", {
  chain <- default_credential_chain()
  nms <- names(chain)
  expect_lt(which(nms == "azure_cli"), which(nms == "auth_code"))
  expect_lt(which(nms == "azure_cli"), which(nms == "device_code"))
})
