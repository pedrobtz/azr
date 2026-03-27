# Extracted from test-api-service.R:114

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-service-create-order", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  service <- api_service$new(
    client = client,
    endpoints = list(
      store = api_store_resource
    )
  )

  order_data <- list(
    id = 54321L,
    petId = 1L,
    quantity = 3L,
    shipDate = "2024-01-15T12:00:00.000Z",
    status = "placed",
    complete = FALSE
  )

  response <- service$store$create_order(order_data)

  expect_type(response, "list")
  expect_true(!is.null(response$id))
  expect_equal(response$status, "placed")
  expect_equal(response$quantity, 3L)
})
