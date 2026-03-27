# Extracted from test-api-service.R:145

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-service-get-order", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  service <- api_service$new(
    client = client,
    endpoints = list(
      store = api_store_resource
    )
  )

  # Create an order first
  order_data <- list(
    id = 98765L,
    petId = 2L,
    quantity = 5L,
    shipDate = "2024-01-15T13:00:00.000Z",
    status = "placed",
    complete = FALSE
  )

  created_order <- service$store$create_order(order_data)

  # Retrieve the order
  retrieved_order <- service$store$get_order(created_order$id)

  expect_type(retrieved_order, "list")
  expect_equal(retrieved_order$id, created_order$id)
  expect_equal(retrieved_order$petId, 2L)
  expect_equal(retrieved_order$quantity, 5L)
})
