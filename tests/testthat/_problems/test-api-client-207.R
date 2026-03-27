# Extracted from test-api-client.R:207

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
client <- api_client$new(
  host_url = "https://petstore.swagger.io/v2"
)
