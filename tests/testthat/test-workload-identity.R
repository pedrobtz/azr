# Helpers for in-object token cache tests

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

test_that("get_token returns valid cached token without reading the file", {
  cred <- new_wi_cred()
  token <- httr2::oauth_token(
    access_token = "cached_wi_token",
    expires_in = 3600
  )
  wi_inject_token(cred, token)

  result <- cred$get_token()

  expect_identical(result$access_token, "cached_wi_token")
})

test_that("get_token calls file read when cached token is expired", {
  cred <- new_wi_cred()
  expired <- httr2::oauth_token(access_token = "old_token", expires_in = 3600)
  expired$expires_at <- Sys.time() - 3600
  wi_inject_token(cred, expired)

  expect_error(cred$get_token(), class = "azr_workload_identity_file_not_found")
})

test_that("get_token calls file read when cache is empty", {
  cred <- new_wi_cred()

  expect_error(cred$get_token(), class = "azr_workload_identity_file_not_found")
})

test_that("get_token stores fetched token in cache", {
  cred <- new_wi_cred()
  fresh <- httr2::oauth_token(access_token = "fresh_token", expires_in = 3600)

  local_mocked_bindings(
    wi_read_token_file = function(...) "federated-jwt",
    wi_exchange_token = function(...) fresh
  )

  result <- cred$get_token()

  key <- rlang::hash(cred$.scope)
  cached <- cred$.__enclos_env__$private$.token_cache[[key]]
  expect_identical(cached$access_token, "fresh_token")
  expect_identical(result$access_token, "fresh_token")
})

test_that("wi_resp_body_json wraps invalid JSON responses", {
  resp <- httr2::response(
    status_code = 502,
    url = "https://login.example/token",
    headers = list("content-type" = "text/html"),
    body = charToRaw("<html>bad gateway</html>")
  )

  expect_error(
    wi_resp_body_json(resp),
    class = "azr_workload_identity_invalid_json_response"
  )
})

test_that("wi_resp_body_json parses valid token JSON responses", {
  resp <- httr2::response(
    headers = list("content-type" = "application/json"),
    body = charToRaw('{"access_token":"abc","expires_in":3600}')
  )

  body <- wi_resp_body_json(resp)

  expect_equal(body$access_token, "abc")
  expect_equal(body$expires_in, 3600)
})
