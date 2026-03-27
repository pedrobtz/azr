# Extracted from test-api-resource.R:64

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "azr", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
vcr::use_cassette("api-resource-create-order", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  store_resource <- api_store_resource$new(
    client = client,
    endpoint = "store"
  )

  order_data <- list(
    id = 12345L,
    petId = 1L,
    quantity = 1L,
    shipDate = "2024-01-15T10:00:00.000Z",
    status = "placed",
    complete = FALSE
  )

  response <- store_resource$create_order(order_data)

  expect_type(response, "list")
  expect_true(!is.null(response$id))
  expect_equal(response$status, "placed")
  expect_equal(response$quantity, 1L)
})
