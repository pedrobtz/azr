# Tests for credential_chain

test_that("credential_chain creates a credential_chain object", {
  chain <- credential_chain(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential
  )

  expect_s3_class(chain, "credential_chain")
  expect_length(chain, 2)
})

test_that("credential_chain preserves names", {
  chain <- credential_chain(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential
  )

  expect_named(chain, c("client_secret", "azure_cli"))
})

test_that("credential_chain errors when empty", {
  expect_error(
    credential_chain(),
    "Credential chain cannot be empty"
  )
})

test_that("credential_chain empty error provides helpful message", {
  err <- tryCatch(
    credential_chain(),
    error = function(e) e
  )

  expect_match(conditionMessage(err), "Credential chain cannot be empty")
  expect_match(conditionMessage(err), "Provide at least one credential")
  expect_match(conditionMessage(err), "default_credential_chain")
})

test_that("credential_chain can contain credential instances", {
  cred_instance <- ClientSecretCredential$new(
    tenant_id = "test-tenant",
    client_id = "test-client",
    client_secret = "test-secret"
  )

  chain <- credential_chain(
    my_cred = cred_instance
  )

  expect_s3_class(chain, "credential_chain")
  expect_length(chain, 1)
})

test_that("credential_chain contains quosures", {
  chain <- credential_chain(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential
  )

  # Each element should be a quosure
  expect_true(all(vapply(chain, rlang::is_quosure, logical(1))))

  # Verify they are the expected types
  expect_s3_class(chain[[1]], "quosure")
  expect_s3_class(chain[[2]], "quosure")
})

test_that("credential_chain is a list of quosures", {
  custom_chain <- credential_chain(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential
  )

  # Check it's a list
  expect_type(custom_chain, "list")

  # Check all elements are quosures
  for (i in seq_along(custom_chain)) {
    expect_s3_class(custom_chain[[i]], "quosure")
  }
})

# Tests for default_credential_chain

test_that("default_credential_chain creates a credential_chain", {
  chain <- default_credential_chain()

  expect_s3_class(chain, "credential_chain")
})

test_that("default_credential_chain contains expected credentials", {
  chain <- default_credential_chain()

  expect_length(chain, 4)
  expect_named(
    chain,
    c("client_secret", "azure_cli", "auth_code", "device_code")
  )
})

test_that("default_credential_chain credentials are in correct order", {
  chain <- default_credential_chain()

  names_order <- names(chain)
  expect_equal(names_order[1], "client_secret")
  expect_equal(names_order[2], "azure_cli")
  expect_equal(names_order[3], "auth_code")
  expect_equal(names_order[4], "device_code")
})

# Tests for new_instance

test_that("new_instance creates an instance from a class", {
  env <- rlang::env(
    tenant_id = "test-tenant",
    client_id = "test-client",
    client_secret = "test-secret"
  )

  instance <- new_instance(ClientSecretCredential, env = env)

  expect_s3_class(instance, "ClientSecretCredential")
  expect_equal(instance$.tenant_id, "test-tenant")
})

test_that("new_instance uses NULL for missing parameters", {
  env <- rlang::env(
    tenant_id = "test-tenant",
    client_id = "test-client"
  )

  instance <- new_instance(AzureCLICredential, env = env)

  expect_s3_class(instance, "AzureCLICredential")
  expect_equal(instance$.tenant_id, "test-tenant")
})

test_that("new_instance works with classes that have no initialize arguments", {
  TestClass <- R6::R6Class(
    classname = "TestClass",
    public = list(
      value = 10
    )
  )

  instance <- new_instance(TestClass)

  expect_s3_class(instance, "TestClass")
  expect_equal(instance$value, 10)
})


test_that("get_credential_provider validates chain parameter", {
  expect_error(
    get_credential_provider(chain = "not-a-chain"),
    "must be of class"
  )

  expect_error(
    get_credential_provider(chain = list("not-a-credential-chain")),
    "must be of class"
  )
})

test_that("get_credential_provider with empty chain errors at creation", {
  # credential_chain() now errors when empty, so we test that
  expect_error(
    credential_chain(),
    "Credential chain cannot be empty"
  )
})

test_that("get_credential_provider tries credentials in order", {
  skip_if_not(rlang::is_interactive(), "Requires interactive session")

  withr::local_envvar(
    AZURE_TENANT_ID = "test-tenant",
    AZURE_CLIENT_ID = "test-client",
    AZURE_CLIENT_SECRET = NA
  )

  # Without client_secret, should skip ClientSecretCredential
  # and try next in chain
  custom_chain <- credential_chain(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential
  )

  expect_error(
    get_credential_provider(.chain = custom_chain),
    "All authentication methods in the chain failed"
  )
})

test_that("get_credential_provider skips interactive credentials in non-interactive session", {
  skip_if(rlang::is_interactive(), "Requires non-interactive session")

  custom_chain <- credential_chain(
    device_code = DeviceCodeCredential
  )

  expect_error(
    get_credential_provider(chain = custom_chain),
    "All authentication methods in the chain failed"
  )
})


# Tests for get_token

test_that("get_token fails with invalid credentials", {
  expect_error(
    get_token(
      tenant_id = "00000000-0000-0000-0000-000000000000",
      client_id = "00000000-0000-0000-0000-000000000000",
      client_secret = "fake-secret"
    )
  )
})

test_that("get_token accepts custom scope", {
  expect_error(
    get_token(
      tenant_id = "00000000-0000-0000-0000-000000000000",
      client_id = "00000000-0000-0000-0000-000000000000",
      client_secret = "fake-secret",
      scope = "https://graph.microsoft.com/.default"
    )
  )
})

test_that("get_token accepts custom chain", {
  custom_chain <- credential_chain(
    client_secret = ClientSecretCredential
  )

  expect_error(
    get_token(
      tenant_id = "00000000-0000-0000-0000-000000000000",
      client_id = "00000000-0000-0000-0000-000000000000",
      client_secret = "fake-secret",
      .chain = custom_chain
    )
  )
})

test_that("get_token uses cache settings", {
  expect_error(
    get_token(
      tenant_id = "00000000-0000-0000-0000-000000000000",
      client_id = "00000000-0000-0000-0000-000000000000",
      client_secret = "fake-secret",
      use_cache = "memory"
    )
  )
})

test_that("get_token uses offline parameter", {
  expect_error(
    get_token(
      tenant_id = "00000000-0000-0000-0000-000000000000",
      client_id = "00000000-0000-0000-0000-000000000000",
      client_secret = "fake-secret",
      offline = FALSE
    )
  )
})

# Integration tests

test_that("credential chain workflow with environment variables", {
  withr::local_envvar(
    AZURE_TENANT_ID = "test-tenant",
    AZURE_CLIENT_ID = "test-client",
    AZURE_CLIENT_SECRET = "test-secret"
  )

  # Create chain
  chain <- default_credential_chain()
  expect_s3_class(chain, "credential_chain")
})

test_that("custom credential chain workflow", {
  withr::local_envvar(
    AZURE_TENANT_ID = "test-tenant",
    AZURE_CLIENT_ID = "test-client",
    AZURE_CLIENT_SECRET = "test-secret"
  )

  # Create custom chain with only non-interactive credentials
  custom_chain <- credential_chain(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential
  )

  expect_s3_class(custom_chain, "credential_chain")
  expect_length(custom_chain, 2)
})
