# Tests for CachedTokenCredential and cached_token_credential_chain()
# (review.md item 11, Phase 2)

test_that("cached_token_credential_chain returns the expected entries", {
  chain <- cached_token_credential_chain()

  expect_s3_class(chain, "credential_chain")
  expect_named(chain, c("auth_code", "device_code", "az_cli"))
  expect_true(all(vapply(chain, inherits, logical(1), "azr_credential_spec")))

  expect_equal(chain$auth_code$args, list(allow_prompt = FALSE))
  expect_equal(chain$device_code$args, list(allow_prompt = FALSE))
  expect_equal(chain$az_cli$args, list(auto_login = FALSE))
})

test_that("CachedTokenCredential construction performs no authentication side effects", {
  testthat::local_mocked_bindings(
    az_cli_is_login = function(...) {
      stop("az_cli_is_login should not be called at construction time")
    },
    az_cli_login = function(...) {
      stop("az_cli_login should not be called at construction time")
    },
    .package = "azr"
  )

  cred <- CachedTokenCredential$new(
    scope = "https://management.azure.com/.default",
    tenant_id = "test-tenant"
  )

  expect_s3_class(cred, "CachedTokenCredential")
})

test_that("CachedTokenCredential errors when no cached tokens are available", {
  testthat::local_mocked_bindings(
    az_cli_is_login = function(...) FALSE,
    .package = "azr"
  )

  cred <- CachedTokenCredential$new(
    scope = "https://management.azure.com/.default",
    tenant_id = "test-tenant"
  )

  expect_error(
    cred$get_token(),
    "All authentication methods in the chain failed",
    class = "azr_credential_chain_failed"
  )
})
