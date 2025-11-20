# Tests for InteractiveCredential (base class)

test_that("InteractiveCredential$is_interactive returns TRUE", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- DeviceCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  expect_true(cred$is_interactive())
})

test_that("InteractiveCredential cannot be used in non-interactive sessions", {
  skip_if(rlang::is_interactive(), "This test requires non-interactive session")

  expect_error(
    DeviceCodeCredential$new(),
    "requires an interactive session"
  )
})

# Tests for DeviceCodeCredential

test_that("DeviceCodeCredential can be initialized", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- DeviceCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  expect_s3_class(cred, "DeviceCodeCredential")
  expect_s3_class(cred, "InteractiveCredential")
  expect_s3_class(cred, "Credential")
  expect_s3_class(cred, "R6")
})

test_that("DeviceCodeCredential initialization with custom parameters", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- DeviceCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id",
    scope = "https://management.azure.com/.default",
    use_cache = "memory",
    offline = FALSE
  )

  expect_equal(cred$.tenant_id, "test-tenant-id")
  expect_equal(cred$.client_id, "test-client-id")
  expect_equal(cred$.scope, "https://management.azure.com/.default")
  expect_equal(cred$.use_cache, "memory")
})

test_that("DeviceCodeCredential uses default cache settings", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- DeviceCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  expect_equal(cred$.use_cache, "disk")
})

test_that("DeviceCodeCredential validates tenant_id", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  expect_error(
    DeviceCodeCredential$new(
      tenant_id = "invalid!tenant",
      client_id = "test-client-id"
    ),
    "not valid"
  )
})

test_that("DeviceCodeCredential validates scope", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  expect_error(
    DeviceCodeCredential$new(
      tenant_id = "test-tenant-id",
      client_id = "test-client-id",
      scope = "invalid scope with spaces"
    ),
    "not valid"
  )
})

test_that("DeviceCodeCredential$get_token requires authentication", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")
  skip("Requires user interaction for device code flow")

  cred <- DeviceCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  # This would prompt for device code authentication
  token <- cred$get_token()
  expect_s3_class(token, "httr2_token")
})

test_that("DeviceCodeCredential$req_auth configures request", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- DeviceCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  req <- httr2::request("https://management.azure.com/subscriptions")
  req_with_auth <- cred$req_auth(req)

  expect_s3_class(req_with_auth, "httr2_request")
})

test_that("DeviceCodeCredential can use environment variables", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  withr::local_envvar(
    AZURE_TENANT_ID = "env-tenant-id",
    AZURE_CLIENT_ID = "env-client-id"
  )

  cred <- DeviceCodeCredential$new()

  expect_equal(cred$.tenant_id, "env-tenant-id")
  expect_equal(cred$.client_id, "env-client-id")
})

# Tests for AuthCodeCredential

test_that("AuthCodeCredential can be initialized", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- AuthCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  expect_s3_class(cred, "AuthCodeCredential")
  expect_s3_class(cred, "InteractiveCredential")
  expect_s3_class(cred, "Credential")
  expect_s3_class(cred, "R6")
})

test_that("AuthCodeCredential initialization with custom parameters", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- AuthCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id",
    scope = "https://management.azure.com/.default",
    use_cache = "memory",
    offline = FALSE
  )

  expect_equal(cred$.tenant_id, "test-tenant-id")
  expect_equal(cred$.client_id, "test-client-id")
  expect_equal(cred$.scope, "https://management.azure.com/.default")
  expect_equal(cred$.use_cache, "memory")
})

test_that("AuthCodeCredential sets redirect_uri", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- AuthCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  expect_true(!is.null(cred$.redirect_uri))
  expect_type(cred$.redirect_uri, "character")
})

test_that("AuthCodeCredential uses default cache settings", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- AuthCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  expect_equal(cred$.use_cache, "disk")
})

test_that("AuthCodeCredential validates tenant_id", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  expect_error(
    AuthCodeCredential$new(
      tenant_id = "invalid!tenant",
      client_id = "test-client-id"
    ),
    "not valid"
  )
})

test_that("AuthCodeCredential validates scope", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  expect_error(
    AuthCodeCredential$new(
      tenant_id = "test-tenant-id",
      client_id = "test-client-id",
      scope = "invalid scope with spaces"
    ),
    "not valid"
  )
})

test_that("AuthCodeCredential$get_token requires authentication", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")
  skip("Requires user interaction and browser for auth code flow")

  cred <- AuthCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  # This would open a browser for authentication
  token <- cred$get_token()
  expect_s3_class(token, "httr2_token")
})

test_that("AuthCodeCredential$req_auth configures request", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  cred <- AuthCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  req <- httr2::request("https://management.azure.com/subscriptions")
  req_with_auth <- cred$req_auth(req)

  expect_s3_class(req_with_auth, "httr2_request")
})

test_that("AuthCodeCredential can use environment variables", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  withr::local_envvar(
    AZURE_TENANT_ID = "env-tenant-id",
    AZURE_CLIENT_ID = "env-client-id"
  )

  cred <- AuthCodeCredential$new()

  expect_equal(cred$.tenant_id, "env-tenant-id")
  expect_equal(cred$.client_id, "env-client-id")
})

test_that("AuthCodeCredential parameters override environment variables", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  withr::local_envvar(
    AZURE_TENANT_ID = "env-tenant-id",
    AZURE_CLIENT_ID = "env-client-id"
  )

  cred <- AuthCodeCredential$new(
    tenant_id = "param-tenant-id",
    client_id = "param-client-id"
  )

  expect_equal(cred$.tenant_id, "param-tenant-id")
  expect_equal(cred$.client_id, "param-client-id")
})

# Tests comparing DeviceCodeCredential and AuthCodeCredential

test_that("DeviceCodeCredential and AuthCodeCredential both inherit InteractiveCredential", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  device_cred <- DeviceCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  auth_cred <- AuthCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  expect_true(inherits(device_cred, "InteractiveCredential"))
  expect_true(inherits(auth_cred, "InteractiveCredential"))
})

test_that("DeviceCodeCredential and AuthCodeCredential use different OAuth endpoints", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  device_cred <- DeviceCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  auth_cred <- AuthCodeCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id"
  )

  expect_match(device_cred$.oauth_url, "devicecode")
  expect_match(auth_cred$.oauth_url, "authorize")
})
