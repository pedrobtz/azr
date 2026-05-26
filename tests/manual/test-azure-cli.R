# Manual tests for AzureCLICredential
#
# These tests are NOT run by `devtools::test()` or CI/CD because they live
# outside `tests/testthat/`. They are intended to be sourced manually from
# an environment that has the `az` CLI installed and a real Azure account
# available to log into.
#
# WARNING: these tests call `az logout` and then drive an interactive
# `az login --use-device-code` flow. Running them will sign the current
# `az` session out and require you to complete a device-code login in the
# browser. Do not run on a machine where you need to keep an existing
# `az` session intact.
#
# See `tests/manual/README.md` for how to run.

library(testthat)
library(azr)

test_that("az_cli_logout clears the session and is_login reports FALSE", {
  az_cli_logout()

  expect_false(az_cli_is_login())
})

test_that("az_cli_login signs in and is_login reports TRUE", {
  skip_if_not(rlang::is_interactive(), "Login requires an interactive session")

  az_cli_login()

  expect_true(az_cli_is_login())
})

test_that("AzureCLICredential gets a token for the default ARM scope", {
  cred <- AzureCLICredential$new(
    scope = azure_scopes$azure_arm
  )

  token <- cred$get_token()

  expect_s3_class(token, "httr2_token")
  expect_true(nzchar(token$access_token))
})

test_that("AzureCLICredential gets tokens for different scopes", {
  cred <- AzureCLICredential$new(
    scope = azure_scopes$azure_arm
  )

  arm_token <- cred$get_token()
  graph_token <- cred$get_token(scope = azure_scopes$azure_graph)

  expect_s3_class(arm_token, "httr2_token")
  expect_s3_class(graph_token, "httr2_token")
  expect_true(nzchar(arm_token$access_token))
  expect_true(nzchar(graph_token$access_token))
  expect_false(identical(arm_token$access_token, graph_token$access_token))
})

test_that("az_cli_logout at the end leaves is_login FALSE", {
  az_cli_logout()

  expect_false(az_cli_is_login())
})
