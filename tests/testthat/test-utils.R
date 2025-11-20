test_that("validate_tenant_id accepts valid tenant IDs", {
  expect_true(validate_tenant_id("common"))
  expect_true(validate_tenant_id("my-tenant-id"))
  expect_true(validate_tenant_id("tenant.with.dots"))
  expect_true(validate_tenant_id("12345-67890"))
  expect_true(validate_tenant_id("abc123DEF456"))
})

test_that("validate_tenant_id rejects non-string inputs", {
  expect_error(validate_tenant_id(123), "must be a single string")
  expect_error(validate_tenant_id(c("a", "b")), "must be a single string")
  expect_error(validate_tenant_id(NULL), "must be a single string")
})

test_that("validate_tenant_id rejects invalid tenant IDs", {
  expect_error(validate_tenant_id("tenant_with_underscore"), "not valid")
  expect_error(validate_tenant_id("tenant with spaces"), "not valid")
  expect_error(validate_tenant_id("tenant/slash"), "not valid")
  expect_error(validate_tenant_id("tenant@special"), "not valid")
})

test_that("validate_scope accepts valid scopes", {
  expect_true(validate_scope("https://management.azure.com/.default"))
  expect_true(validate_scope("openid"))
  expect_true(validate_scope("user.read"))
  expect_true(validate_scope(c("openid", "profile", "email")))
  expect_true(validate_scope("https://graph.microsoft.com/.default"))
})

test_that("validate_scope rejects non-character inputs", {
  expect_error(validate_scope(123), "must be a character vector")
  expect_error(validate_scope(NULL), "must be a character vector")
  expect_error(validate_scope(list("a")), "must be a character vector")
})

test_that("validate_scope rejects invalid scopes", {
  expect_error(validate_scope("scope with spaces"), "not valid")
  expect_error(validate_scope("scope@invalid"), "not valid")
  expect_error(validate_scope(c("valid.scope", "invalid scope")), "not valid")
})

test_that("get_scope_resource extracts resource from HTTP scope", {
  result <- get_scope_resource("https://management.azure.com/.default")
  expect_equal(result, "https://management.azure.com")

  result <- get_scope_resource("https://graph.microsoft.com/.default")
  expect_equal(result, "https://graph.microsoft.com")

  result <- get_scope_resource("https://vault.azure.net/.default")
  expect_equal(result, "https://vault.azure.net")
})

test_that("get_scope_resource handles trailing slash", {
  result <- get_scope_resource("https://management.azure.com/")
  expect_equal(result, "https://management.azure.com")
})

test_that("get_scope_resource returns NULL for non-HTTP scopes", {
  expect_null(get_scope_resource("openid"))
  expect_null(get_scope_resource("user.read"))
})

test_that("get_scope_resource returns NULL for multiple HTTP scopes", {
  scopes <- c("https://management.azure.com/.default", "https://graph.microsoft.com/.default")
  expect_null(get_scope_resource(scopes))
})

test_that("get_scope_resource returns NULL for no HTTP scopes", {
  scopes <- c("openid", "profile", "email")
  expect_null(get_scope_resource(scopes))
})

test_that("is_empty detects NULL", {
  expect_true(is_empty(NULL))
})

test_that("is_empty detects NA values", {
  expect_true(is_empty(NA))
  expect_true(is_empty(NA_character_))
  expect_true(is_empty(NA_integer_))
})

test_that("is_empty detects empty strings", {
  expect_true(is_empty(""))
})

test_that("is_empty returns FALSE for non-empty values", {
  expect_false(is_empty("test"))
  expect_false(is_empty(123))
  expect_false(is_empty(TRUE))
})

test_that("is_empty returns FALSE for vectors with multiple elements", {
  expect_false(is_empty(c("a", "b")))
  expect_false(is_empty(1:10))
})

test_that("is_empty_vec works on lists", {
  x <- list(a = "value", b = "", c = NA, d = NULL, e = "test")
  result <- is_empty_vec(x)

  expect_equal(length(result), 5)
  expect_false(result[1])  # "value"
  expect_true(result[2])   # ""
  expect_true(result[3])   # NA
  expect_true(result[4])   # NULL
  expect_false(result[5])  # "test"
})

test_that("is_empty_vec returns logical vector", {
  x <- list(a = 1, b = NULL, c = "test")
  result <- is_empty_vec(x)

  expect_type(result, "logical")
  expect_length(result, 3)
})

test_that("get_env_config returns formatted bullet list", {
  withr::local_envvar(
    AZURE_TENANT_ID = NA,
    AZURE_CLIENT_ID = NA,
    AZURE_CLIENT_SECRET = NA,
    AZURE_AUTHORITY_HOST = NA
  )

  result <- get_env_config()

  expect_type(result, "character")
  expect_length(result, 4)
  expect_named(result, c("*", "*", "*", "*"))
})

test_that("get_env_config shows environment variables when set", {
  withr::local_envvar(
    AZURE_TENANT_ID = "my-tenant",
    AZURE_CLIENT_ID = "my-client",
    AZURE_CLIENT_SECRET = "my-secret",
    AZURE_AUTHORITY_HOST = "login.microsoftonline.us"
  )

  result <- get_env_config()

  expect_match(result[1], "my-tenant")
  expect_match(result[2], "my-client")
  expect_match(result[3], "REDACTED")
  expect_match(result[4], "login.microsoftonline.us")
})

test_that("get_env_config shows defaults when not set", {
  withr::local_envvar(
    AZURE_TENANT_ID = "",
    AZURE_CLIENT_ID = "",
    AZURE_CLIENT_SECRET = "",
    AZURE_AUTHORITY_HOST = ""
  )

  result <- get_env_config()

  expect_match(result[1], "default")
  expect_match(result[2], "default")
  expect_match(result[3], "not set")
  expect_match(result[4], "default")
})
