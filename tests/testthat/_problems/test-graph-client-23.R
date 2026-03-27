# Extracted from test-graph-client.R:23

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
graph <- azr_graph_client()
