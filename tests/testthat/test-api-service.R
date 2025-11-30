test_that("api_service can be initialized with client", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  service <- api_service$new(
    client = client
  )

  expect_true(R6::is.R6(service))
  expect_true(inherits(service, "api_service"))
  expect_true(R6::is.R6(service$.client))
  expect_true(inherits(service$.client, "api_client"))
})

test_that("api_service can create resources from endpoints", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  service <- api_service$new(
    client = client,
    endpoints = list(
      store = api_store_resource
    )
  )

  expect_true(R6::is.R6(service))
  expect_true(!is.null(service$store))
  expect_true(R6::is.R6(service$store))
  expect_true(inherits(service$store, "api_resource"))
  expect_true(inherits(service$store, "api_store_resource"))
})

test_that("api_service creates default api_resource when endpoint class is NULL", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  service <- api_service$new(
    client = client,
    endpoints = list(
      v1 = NULL
    )
  )

  expect_true(R6::is.R6(service$v1))
  expect_true(inherits(service$v1, "api_resource"))
  expect_false(inherits(service$v1, "api_store_resource"))
})

test_that("api_service validates endpoints parameter", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  expect_error(
    api_service$new(client = client, endpoints = "not_a_list"),
    "endpoints.*must be a list"
  )
})

test_that("api_service validates endpoint paths", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  # Empty string endpoint
  expect_error(
    api_service$new(
      client = client,
      endpoints = stats::setNames(list(NULL), "")
    ),
    "must not be an empty string"
  )

  # Endpoint with spaces
  expect_error(
    api_service$new(
      client = client,
      endpoints = list("has space" = NULL)
    ),
    "contains spaces"
  )

  # Endpoint with invalid characters
  expect_error(
    api_service$new(
      client = client,
      endpoints = list("invalid@char" = NULL)
    ),
    "invalid characters"
  )
})

test_that("api_service validates endpoint resource classes", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  expect_error(
    api_service$new(
      client = client,
      endpoints = list(store = "not_an_r6_class")
    ),
    "must specify an R6 class"
  )
})

test_that("api_service endpoint resources can make HTTP requests", {
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
})

test_that("api_service endpoint resources can retrieve data", {
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
})

test_that("api_service can handle multiple endpoints", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  service <- api_service$new(
    client = client,
    endpoints = list(
      store = api_store_resource,
      v1 = NULL,
      beta = NULL
    )
  )

  expect_true(!is.null(service$store))
  expect_true(!is.null(service$v1))
  expect_true(!is.null(service$beta))

  expect_true(inherits(service$store, "api_store_resource"))
  expect_true(inherits(service$v1, "api_resource"))
  expect_true(inherits(service$beta, "api_resource"))
})

test_that("api_service endpoint fields are locked", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  service <- api_service$new(
    client = client,
    endpoints = list(
      store = api_store_resource
    )
  )

  # Try to modify the locked endpoint field
  expect_error(
    service$store <- NULL,
    "locked"
  )
})

test_that("api_service accepts valid endpoint path characters", {
  client <- api_client$new(
    host_url = "https://petstore.swagger.io/v2"
  )

  # Valid paths with various allowed characters
  service <- api_service$new(
    client = client,
    endpoints = list(
      "v1.0" = NULL,
      "api-beta" = NULL,
      "test_endpoint" = NULL,
      "v2/store" = NULL
    )
  )

  expect_true(!is.null(service[["v1.0"]]))
  expect_true(!is.null(service[["api-beta"]]))
  expect_true(!is.null(service[["test_endpoint"]]))
  expect_true(!is.null(service[["v2/store"]]))
})
