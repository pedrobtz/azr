test_that("azr_graph_client returns an api_service", {
  graph <- azr_graph_client()

  expect_true(R6::is.R6(graph))
  expect_true(inherits(graph, "api_service"))
})

test_that("azr_graph_client creates a service with v1.0 and beta endpoints", {
  graph <- azr_graph_client()

  # Check that both endpoints exist
  expect_true(!is.null(graph$v1.0))
  expect_true(!is.null(graph$beta))

  # Check that endpoints are api_graph_resource instances
  expect_true(R6::is.R6(graph$v1.0))
  expect_true(R6::is.R6(graph$beta))
  expect_true(inherits(graph$v1.0, "api_graph_resource"))
  expect_true(inherits(graph$beta, "api_graph_resource"))
})

test_that("azr_graph_client creates api_client with correct host_url", {
  graph <- azr_graph_client()

  # Access the internal client
  expect_true(R6::is.R6(graph$.client))
  expect_true(inherits(graph$.client, "api_client"))
  expect_equal(graph$.client$.host_url, "https://graph.microsoft.com")
})

test_that("azr_graph_client service is locked", {
  graph <- azr_graph_client()

  # Try to modify a locked endpoint field
  expect_error(
    graph$v1.0 <- NULL,
    "locked"
  )
})
