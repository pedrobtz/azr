# Manual tests for DefaultCredential
#
# These tests are NOT run by `devtools::test()` or CI/CD because they live
# outside `tests/testthat/`. They are intended to be sourced manually from
# an environment that has access to real Azure infrastructure.
#
# See `tests/manual/README.md` for how to run.

library(testthat)
library(azr)

test_that("DefaultCredential acquires a token from a real provider", {
  cred <- DefaultCredential$new(verbose = TRUE)

  token <- cred$get_token()

  expect_s3_class(token, "httr2_token")
  expect_true(nzchar(token$access_token))
})
