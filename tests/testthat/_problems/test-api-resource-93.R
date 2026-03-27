# Extracted from test-api-resource.R:93

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-resource-get-order", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  store_resource <- api_store_resource$new(
    client = client,
    endpoint = "store"
  )

  # First create an order
  order_data <- list(
    id = 67890L,
    petId = 1L,
    quantity = 2L,
    shipDate = "2024-01-15T11:00:00.000Z",
    status = "placed",
    complete = FALSE
  )

  created_order <- store_resource$create_order(order_data)

  # Get the order by ID
  retrieved_order <- store_resource$get_order(created_order$id)

  expect_type(retrieved_order, "list")
  expect_equal(retrieved_order$id, created_order$id)
  expect_equal(retrieved_order$petId, 1L)
  expect_equal(retrieved_order$quantity, 2L)
  expect_equal(retrieved_order$status, "placed")
})
