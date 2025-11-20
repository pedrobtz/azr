test_that("ClientSecretCredential can be initialized", {
  cred <- ClientSecretCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id",
    client_secret = "test-secret"
  )

  expect_s3_class(cred, "ClientSecretCredential")
  expect_s3_class(cred, "Credential")
  expect_s3_class(cred, "R6")
})

test_that("ClientSecretCredential initialization with custom parameters", {
  cred <- ClientSecretCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id",
    client_secret = "test-secret",
    scope = "https://management.azure.com/.default"
  )

  expect_equal(cred$.tenant_id, "test-tenant-id")
  expect_equal(cred$.client_id, "test-client-id")
  expect_equal(cred$.client_secret, "test-secret")
  expect_equal(cred$.scope, "https://management.azure.com/.default")
})

test_that("ClientSecretCredential$is_interactive returns FALSE", {
  cred <- ClientSecretCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id",
    client_secret = "test-secret"
  )

  expect_false(cred$is_interactive())
})

test_that("ClientSecretCredential validates client_secret is provided", {
  expect_error(
    ClientSecretCredential$new(
      tenant_id = "test-tenant-id",
      client_id = "test-client-id",
      client_secret = NULL
    ),
    "cannot be NULL or NA"
  )
})

test_that("ClientSecretCredential validates client_secret is not NA", {
  expect_error(
    ClientSecretCredential$new(
      tenant_id = "test-tenant-id",
      client_id = "test-client-id",
      client_secret = NA_character_
    ),
    "`secret` must be a single string or `NULL`"
  )
})

test_that("ClientSecretCredential validates tenant_id", {
  expect_error(
    ClientSecretCredential$new(
      tenant_id = "invalid!tenant",
      client_id = "test-client-id",
      client_secret = "test-secret"
    ),
    "not valid"
  )
})

test_that("ClientSecretCredential validates scope", {
  expect_error(
    ClientSecretCredential$new(
      tenant_id = "test-tenant-id",
      client_id = "test-client-id",
      client_secret = "test-secret",
      scope = "invalid scope with spaces"
    ),
    "not valid"
  )
})

test_that("ClientSecretCredential$get_token fails with invalid credentials", {
  cred <- ClientSecretCredential$new(
    tenant_id = "invalid-tenant",
    client_id = "invalid-client",
    client_secret = "invalid-secret"
  )

  # This should fail because the credentials are invalid
  expect_error(cred$get_token())
})

test_that("ClientSecretCredential$get_token fails with fake credentials", {
  cred <- ClientSecretCredential$new(
    tenant_id = "00000000-0000-0000-0000-000000000000",
    client_id = "00000000-0000-0000-0000-000000000000",
    client_secret = "fake-secret-that-does-not-exist"
  )

  # This should fail because these are not real Azure credentials
  expect_error(cred$get_token())
})

test_that("ClientSecretCredential$req_auth configures request authentication", {
  cred <- ClientSecretCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id",
    client_secret = "test-secret"
  )

  req <- httr2::request("https://management.azure.com/subscriptions")
  req_with_auth <- cred$req_auth(req)

  # Verify that the request object is returned and has been modified
  expect_s3_class(req_with_auth, "httr2_request")
})

test_that("ClientSecretCredential uses default scope when not specified", {
  cred <- ClientSecretCredential$new(
    tenant_id = "test-tenant-id",
    client_id = "test-client-id",
    client_secret = "test-secret"
  )

  # Should use default Azure ARM scope
  expect_equal(cred$.scope, default_azure_scope("azure_arm"))
})

test_that("ClientSecretCredential can use environment variables", {
  withr::local_envvar(
    AZURE_TENANT_ID = "env-tenant-id",
    AZURE_CLIENT_ID = "env-client-id",
    AZURE_CLIENT_SECRET = "env-client-secret"
  )

  cred <- ClientSecretCredential$new()

  expect_equal(cred$.tenant_id, "env-tenant-id")
  expect_equal(cred$.client_id, "env-client-id")
  expect_equal(cred$.client_secret, "env-client-secret")
})

test_that("ClientSecretCredential parameters override environment variables", {
  withr::local_envvar(
    AZURE_TENANT_ID = "env-tenant-id",
    AZURE_CLIENT_ID = "env-client-id",
    AZURE_CLIENT_SECRET = "env-client-secret"
  )

  cred <- ClientSecretCredential$new(
    tenant_id = "param-tenant-id",
    client_id = "param-client-id",
    client_secret = "param-client-secret"
  )

  expect_equal(cred$.tenant_id, "param-tenant-id")
  expect_equal(cred$.client_id, "param-client-id")
  expect_equal(cred$.client_secret, "param-client-secret")
})
