# Manual tests for azr_graph_client
#
# These tests are NOT run by `devtools::test()` or CI/CD because they live
# outside `tests/testthat/`. They are intended to be sourced manually from
# an environment that has access to real Azure infrastructure and where the
# current credential maps to a user (the `/me` endpoint requires a delegated
# user identity, not a service principal).
#
# See `tests/manual/README.md` for how to run.

library(testthat)
library(azr)

test_that("azr_graph_client fetches the current user from v1.0/me", {
  graph <- azr_graph_client()

  me <- graph$v1.0$me()

  expect_true(nzchar(me$id))
  expect_true(nzchar(me$userPrincipalName))
})
