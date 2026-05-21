test_that("api_log_analytics_client binds subscription_id and resource_id", {
  client <- api_log_analytics_client$new(
    subscription_id = "sub-123",
    resource_id = "rg-abc"
  )

  expect_equal(client$.subscription_id, "sub-123")
  expect_equal(client$.resource_id, "rg-abc")
  expect_equal(client$.api_version, "v1")
  expect_equal(
    client$.host_url,
    "https://api.loganalytics.io/v1/subscriptions/sub-123/resourceGroups/rg-abc"
  )
  expect_equal(
    client$.provider$.scope,
    default_azure_scope("azure_log_analytics")
  )
})

test_that("api_log_analytics_client locks subscription_id and resource_id", {
  client <- api_log_analytics_client$new(
    subscription_id = "sub-123",
    resource_id = "rg-abc"
  )

  expect_error(client$.subscription_id <- "other", "locked")
  expect_error(client$.resource_id <- "other", "locked")
})

test_that("api_log_analytics_client rejects missing subscription_id", {
  expect_error(
    api_log_analytics_client$new(resource_id = "rg-abc"),
    "subscription_id"
  )
})

test_that("api_log_analytics_client rejects missing resource_id", {
  expect_error(
    api_log_analytics_client$new(subscription_id = "sub-123"),
    "resource_id"
  )
})

test_that("api_log_analytics_client accepts a custom endpoint", {
  client <- api_log_analytics_client$new(
    subscription_id = "sub-123",
    resource_id = "rg-abc",
    endpoint = "api.loganalytics.us"
  )
  expect_equal(
    client$.host_url,
    "https://api.loganalytics.us/v1/subscriptions/sub-123/resourceGroups/rg-abc"
  )
})

test_that("log_analytics_host_url normalizes scheme and trailing slashes", {
  expect_equal(
    log_analytics_host_url("https://api.loganalytics.us/"),
    "https://api.loganalytics.us"
  )
})

test_that("log_analytics_host_url rejects empty endpoint", {
  expect_error(log_analytics_host_url("https://"), "endpoint")
})

test_that("api_log_analytics_client rejects empty api_version", {
  expect_error(
    api_log_analytics_client$new(
      subscription_id = "sub-123",
      resource_id = "rg-abc",
      api_version = ""
    ),
    "api_version"
  )
})

test_that("api_log_analytics_client accepts a custom scope", {
  client <- api_log_analytics_client$new(
    subscription_id = "sub-123",
    resource_id = "rg-abc",
    scope = "https://example.loganalytics.io/.default"
  )
  expect_equal(
    client$.provider$.scope,
    "https://example.loganalytics.io/.default"
  )
})

test_that("api_log_analytics_client uses supplied credential provider", {
  provider <- ClientSecretCredential$new(
    tenant_id = "common",
    client_id = "test-client",
    client_secret = "test-secret"
  )

  client <- api_log_analytics_client$new(
    subscription_id = "sub-123",
    resource_id = "rg-abc",
    provider = provider,
    chain = "not-a-chain"
  )

  expect_identical(client$.provider, provider)
})

test_that("api_log_analytics_client validates supplied credential provider", {
  expect_error(
    api_log_analytics_client$new(
      subscription_id = "sub-123",
      resource_id = "rg-abc",
      provider = list()
    ),
    "provider"
  )
})

test_that("$query() builds the expected request", {
  client <- api_log_analytics_client$new(
    subscription_id = "sub-123",
    resource_id = "rg-abc"
  )

  req <- client$.build_request(
    path = "query",
    method = "post",
    body = list(query = "Heartbeat | take 1", timespan = "PT1H"),
    query = list(scope = "hierarchy")
  )

  expect_equal(req$method, "POST")
  expect_match(
    req$url,
    "https://api.loganalytics.io/v1/subscriptions/sub-123/resourceGroups/rg-abc/query"
  )
  expect_match(req$url, "scope=hierarchy")
  expect_equal(req$body$content_type, "application/json")
})

test_that("$query() rejects an empty query string", {
  client <- api_log_analytics_client$new(
    subscription_id = "sub-123",
    resource_id = "rg-abc"
  )

  expect_error(client$query(query = ""), "query")
})

test_that("log_analytics_parse_tables coerces a single table to a data.frame", {
  parsed <- list(
    tables = list(
      list(
        name = "PrimaryResult",
        columns = list(
          list(name = "Category", type = "string"),
          list(name = "count_", type = "long")
        ),
        rows = list(
          list("Administrative", 20839L),
          list("Recommendation", 122L)
        )
      )
    )
  )

  df <- log_analytics_parse_tables(parsed)

  expect_s3_class(df, "data.frame")
  expect_equal(names(df), c("Category", "count_"))
  expect_equal(df$Category, c("Administrative", "Recommendation"))
  expect_equal(df$count_, c(20839L, 122L))
})

test_that("log_analytics_parse_tables returns a named list when multiple tables", {
  parsed <- list(
    tables = list(
      list(
        name = "T1",
        columns = list(list(name = "x", type = "long")),
        rows = list(list(1L))
      ),
      list(
        name = "T2",
        columns = list(list(name = "y", type = "string")),
        rows = list(list("a"))
      )
    )
  )

  out <- log_analytics_parse_tables(parsed)

  expect_named(out, c("T1", "T2"))
  expect_equal(out$T1$x, 1L)
  expect_equal(out$T2$y, "a")
})

test_that("log_analytics_parse_tables handles empty rows and NULL values", {
  parsed <- list(
    tables = list(
      list(
        name = "Empty",
        columns = list(
          list(name = "x", type = "long"),
          list(name = "y", type = "string")
        ),
        rows = list()
      )
    )
  )

  df <- log_analytics_parse_tables(parsed)
  expect_equal(nrow(df), 0L)
  expect_equal(names(df), c("x", "y"))

  parsed_nulls <- list(
    tables = list(
      list(
        name = "WithNulls",
        columns = list(
          list(name = "x", type = "long"),
          list(name = "y", type = "real")
        ),
        rows = list(list(NULL, NULL), list(1L, 2.5))
      )
    )
  )

  df2 <- log_analytics_parse_tables(parsed_nulls)
  expect_equal(df2$x, c(NA_integer_, 1L))
  expect_equal(df2$y, c(NA_real_, 2.5))
})

test_that("azr_log_analytics_client passes arguments through", {
  client <- azr_log_analytics_client(
    subscription_id = "sub-123",
    resource_id = "rg-abc",
    endpoint = "api.loganalytics.us",
    scope = "https://example.loganalytics.io/.default"
  )

  expect_s3_class(client, "api_log_analytics_client")
  expect_equal(client$.subscription_id, "sub-123")
  expect_equal(client$.resource_id, "rg-abc")
  expect_equal(
    client$.host_url,
    "https://api.loganalytics.us/v1/subscriptions/sub-123/resourceGroups/rg-abc"
  )
  expect_equal(
    client$.provider$.scope,
    "https://example.loganalytics.io/.default"
  )
})
