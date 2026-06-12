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

test_that("credential_chain contains credential_spec entries", {
  chain <- credential_chain(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential
  )

  # Each element should be an azr_credential_spec
  expect_true(all(vapply(chain, inherits, logical(1), "azr_credential_spec")))

  # Verify they are the expected types
  expect_s3_class(chain[[1]], "azr_credential_spec")
  expect_s3_class(chain[[2]], "azr_credential_spec")
})

test_that("credential_chain is a list of credential_spec entries", {
  custom_chain <- credential_chain(
    client_secret = ClientSecretCredential,
    azure_cli = AzureCLICredential
  )

  # Check it's a list
  expect_type(custom_chain, "list")

  # Check all elements are credential_spec entries
  for (i in seq_along(custom_chain)) {
    expect_s3_class(custom_chain[[i]], "azr_credential_spec")
  }
})

# Tests for default_credential_chain

test_that("default_credential_chain creates a credential_chain", {
  chain <- default_credential_chain()

  expect_s3_class(chain, "credential_chain")
})

test_that("default_credential_chain contains expected credentials", {
  chain <- default_credential_chain()

  expect_length(chain, 6)
  expect_named(
    chain,
    c(
      "client_secret",
      "workload_identity",
      "managed_identity",
      "azure_cli",
      "auth_code",
      "device_code"
    )
  )
})

test_that("default_credential_chain credentials are in correct order", {
  chain <- default_credential_chain()

  names_order <- names(chain)
  expect_equal(names_order[1], "client_secret")
  expect_equal(names_order[2], "workload_identity")
  expect_equal(names_order[3], "managed_identity")
  expect_equal(names_order[4], "azure_cli")
  expect_equal(names_order[5], "auth_code")
  expect_equal(names_order[6], "device_code")
})

# Tests for DefaultCredential

test_that("DefaultCredential errors on invalid use_cache at construction time", {
  expect_error(
    DefaultCredential$new(use_cache = "invalid"),
    class = "rlang_error"
  )
})

test_that("DefaultCredential accepts valid use_cache values", {
  expect_no_error(DefaultCredential$new(use_cache = "disk"))
  expect_no_error(DefaultCredential$new(use_cache = "memory"))
})

# Tests for new_instance

test_that("new_instance creates an instance from a class", {
  context <- list(
    tenant_id = "test-tenant",
    client_id = "test-client",
    client_secret = "test-secret"
  )

  instance <- new_instance(ClientSecretCredential, context = context)

  expect_s3_class(instance, "ClientSecretCredential")
  expect_equal(instance$.tenant_id, "test-tenant")
})

test_that("new_instance only forwards context values accepted by initialize()", {
  testthat::local_mocked_bindings(
    az_cli_is_login = function(...) TRUE,
    .package = "azr"
  )
  context <- list(
    scope = "https://management.azure.com/.default",
    tenant_id = "test-tenant",
    client_id = "test-client"
  )

  # ManagedIdentityCredential$initialize() only accepts scope/client_id; if
  # tenant_id were forwarded, this would error with "unused argument".
  instance <- new_instance(ManagedIdentityCredential, context = context)

  expect_s3_class(instance, "ManagedIdentityCredential")
})

test_that("new_instance ignores unmatched context values for classes with ... in initialize()", {
  TestDotsClass <- R6::R6Class(
    classname = "TestDotsClass",
    public = list(
      tenant_id = NULL,
      initialize = function(tenant_id = NULL, ...) {
        self$tenant_id <- tenant_id
      }
    )
  )

  context <- list(tenant_id = "test-tenant", client_secret = "test-secret")

  instance <- new_instance(TestDotsClass, context = context)

  expect_equal(instance$tenant_id, "test-tenant")
})

test_that("new_instance works with classes that have no initialize arguments", {
  TestClass <- R6::R6Class(
    classname = "TestClass",
    public = list(
      value = 10
    )
  )

  instance <- new_instance(TestClass, context = list())

  expect_s3_class(instance, "TestClass")
  expect_equal(instance$value, 10)
})

# Tests for build_credential_context

test_that("build_credential_context contains exactly the eight documented names", {
  context <- build_credential_context(
    scope = "https://management.azure.com/.default",
    tenant_id = "test-tenant",
    client_id = "test-client",
    client_secret = "test-secret",
    use_cache = "memory",
    offline = FALSE,
    oauth_host = "https://login.microsoftonline.com",
    oauth_endpoint = "token"
  )

  expect_named(
    context,
    c(
      "scope",
      "tenant_id",
      "client_id",
      "client_secret",
      "use_cache",
      "offline",
      "oauth_host",
      "oauth_endpoint"
    )
  )
})

test_that("build_credential_context drops NULL entries so constructor defaults apply", {
  context <- build_credential_context()

  expect_named(context, c("use_cache", "offline"))
  expect_equal(context$use_cache, "disk")
  expect_true(context$offline)
})

test_that("build_credential_context never includes interactive", {
  context <- build_credential_context(
    scope = "s",
    tenant_id = "t",
    client_id = "c",
    client_secret = "x",
    use_cache = "memory",
    offline = FALSE,
    oauth_host = "h",
    oauth_endpoint = "e"
  )

  expect_false("interactive" %in% names(context))
})

# Tests for the AzureCLICredential cli_auto_login fix (review.md item 11)

test_that("get_credential_provider does not leak interactive into AzureCLICredential", {
  testthat::local_mocked_bindings(
    az_cli_is_login = function(...) FALSE,
    .package = "azr"
  )
  withr::local_options(azr.cli_auto_login = FALSE)

  chain <- credential_chain(azure_cli = AzureCLICredential)

  err <- tryCatch(
    get_credential_provider(chain = chain, allow_interactive = TRUE, verbose = FALSE),
    error = function(e) e
  )

  # With the cli_auto_login default (FALSE), AzureCLICredential should report
  # that the user is not logged in, rather than attempting az_cli_login()
  # because `allow_interactive = TRUE` leaked into its constructor.
  expect_match(conditionMessage(err), "not logged in to Azure CLI")
})


test_that("try_build_credential skips interactive credentials in non-interactive sessions", {
  chain <- credential_chain(DeviceCodeCredential)
  context <- list(
    scope = "https://management.azure.com/.default",
    tenant_id = "common",
    client_id = "test-client"
  )

  result <- try_build_credential(
    chain[[1]],
    "device_code",
    context = context,
    interactive = FALSE
  )

  expect_null(result$obj)
  expect_match(result$error, "interactive session")
})

test_that("try_build_credential builds workload identity credential", {
  chain <- credential_chain(WorkloadIdentityCredential)
  context <- list(
    scope = "https://management.azure.com/.default",
    tenant_id = "common",
    client_id = "test-client",
    token_file_path = tempfile()
  )

  result <- try_build_credential(chain[[1]], "workload", context = context)

  expect_null(result$error)
  expect_s3_class(result$obj, "WorkloadIdentityCredential")
})

test_that("try_build_credential resolves namespace-qualified credential class", {
  chain <- credential_chain(azr::WorkloadIdentityCredential)
  context <- list(
    scope = "https://management.azure.com/.default",
    tenant_id = "common",
    client_id = "test-client",
    token_file_path = tempfile()
  )

  result <- try_build_credential(chain[[1]], "workload", context = context)

  expect_null(result$error)
  expect_s3_class(result$obj, "WorkloadIdentityCredential")
})

test_that("credential_chain errors for an undefined credential class", {
  # Chain entries are validated/built eagerly, so an undefined class fails
  # at definition time rather than later inside try_build_credential().
  expect_error(
    credential_chain(FakeCredential),
    "not found"
  )
})

test_that("try_build_credential reports credentials that do not inherit from Credential", {
  NotACredential <- R6::R6Class(
    classname = "NotACredential",
    public = list(initialize = function(...) invisible(NULL))
  )

  chain <- credential_chain(NotACredential)
  context <- list(
    scope = "https://management.azure.com/.default",
    tenant_id = "common",
    client_id = "test-client"
  )

  result <- try_build_credential(chain[[1]], "fake", context = context)

  expect_null(result$obj)
  expect_match(result$error, "does not inherit")
})

test_that("try_build_credential passes context values to device code credential", {
  scope <- "https://graph.microsoft.com/.default"
  chain <- credential_chain(DeviceCodeCredential)
  context <- list(
    scope = scope,
    tenant_id = "common",
    client_id = "test-client",
    use_cache = "memory",
    offline = FALSE,
    allow_prompt = FALSE
  )

  result <- try_build_credential(chain[[1]], "device_code", context = context)
  cred <- result$obj

  expect_s3_class(cred, "DeviceCodeCredential")
  expect_equal(cred$.scope, scope)
  expect_equal(cred$.tenant_id, "common")
  expect_equal(cred$.client_id, "test-client")
  expect_equal(cred$.use_cache, "memory")
  expect_false(cred$is_interactive())
})

test_that("try_build_credential passes context values to workload identity credential", {
  token_file_path <- tempfile()
  chain <- credential_chain(WorkloadIdentityCredential)
  context <- list(
    scope = "https://management.azure.com/.default",
    tenant_id = "common",
    client_id = "test-client",
    token_file_path = token_file_path
  )

  result <- try_build_credential(chain[[1]], "workload", context = context)
  cred <- result$obj

  expect_s3_class(cred, "WorkloadIdentityCredential")
  expect_equal(cred$.tenant_id, "common")
  expect_equal(cred$.client_id, "test-client")
  expect_equal(cred$.token_file_path, token_file_path)
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

# Tests for credential_spec()

test_that("credential_spec errors when class is not an R6 generator", {
  expect_error(
    credential_spec("not-a-class"),
    "must be an R6 credential class generator"
  )
})

test_that("credential_spec errors on unnamed arguments", {
  expect_error(
    credential_spec(ClientSecretCredential, "unnamed-value"),
    "must be named"
  )
})

test_that("credential_spec errors on unknown arguments", {
  expect_error(
    credential_spec(ClientSecretCredential, bogus_arg = "x"),
    "Unknown argument"
  )
})

test_that("credential_spec accepts known initialize() arguments", {
  spec <- credential_spec(ClientSecretCredential, client_id = "my-client-id")

  expect_s3_class(spec, "azr_credential_spec")
  expect_identical(spec$class, ClientSecretCredential)
  expect_equal(spec$args, list(client_id = "my-client-id"))
})

# Tests for format/print redaction (review.md item 11, Phase 2)

test_that("format.azr_credential_spec redacts sensitive arguments", {
  spec <- credential_spec(
    ClientSecretCredential,
    client_id = "my-client-id",
    client_secret = "super-secret-value"
  )

  out <- format(spec)

  expect_match(out, "my-client-id", fixed = TRUE)
  expect_false(grepl("super-secret-value", out, fixed = TRUE))
  expect_match(out, "<hidden>", fixed = TRUE)
})

test_that("print.azr_credential_spec never reveals secrets", {
  spec <- credential_spec(
    ClientSecretCredential,
    client_secret = "super-secret-value"
  )

  out <- capture.output(print(spec))

  expect_false(any(grepl("super-secret-value", out, fixed = TRUE)))
})

test_that("print.credential_chain never reveals secrets", {
  chain <- credential_chain(
    client_secret = credential_spec(
      ClientSecretCredential,
      client_secret = "super-secret-value"
    )
  )

  out <- capture.output(print(chain))

  expect_false(any(grepl("super-secret-value", out, fixed = TRUE)))
})

# Tests for build_credential() merge precedence (review.md item 11, Phase 2)

test_that("build_credential: entry argument overrides context value", {
  context <- list(
    tenant_id = "context-tenant",
    client_id = "context-client",
    client_secret = "context-secret"
  )
  spec <- credential_spec(ClientSecretCredential, tenant_id = "spec-tenant")

  cred <- build_credential(spec, context = context)

  expect_equal(cred$.tenant_id, "spec-tenant")
  expect_equal(cred$.client_id, "context-client")
})

test_that("build_credential: omitted argument falls through to constructor default", {
  context <- list(tenant_id = "test-tenant")
  spec <- credential_spec(AzureCLICredential)

  cred <- build_credential(spec, context = context)

  expect_true(cred$use_bridge)
})

test_that("build_credential: explicit NULL entry argument reaches the constructor (regression guard for modifyList)", {
  TestNullClass <- R6::R6Class(
    classname = "TestNullClass",
    public = list(
      client_id = NULL,
      initialize = function(client_id = "default-client-id") {
        self$client_id <- client_id
      }
    )
  )

  spec <- credential_spec(TestNullClass, client_id = NULL)
  context <- list(client_id = "context-client-id")

  cred <- build_credential(spec, context = context)

  expect_null(cred$client_id)
})

test_that("build_credential: pre-built instance receives no context merge", {
  cred_instance <- ClientSecretCredential$new(
    tenant_id = "instance-tenant",
    client_id = "instance-client",
    client_secret = "instance-secret"
  )
  context <- list(tenant_id = "context-tenant", client_id = "context-client")

  result <- build_credential(cred_instance, context = context)

  expect_identical(result, cred_instance)
  expect_equal(result$.tenant_id, "instance-tenant")
})

# Tests for side-effect-free chain definition and construction
# (review.md item 11, Phase 2)

test_that("defining a chain performs no authentication side effects", {
  testthat::local_mocked_bindings(
    az_cli_is_login = function(...) {
      stop("az_cli_is_login should not be called when defining a chain")
    },
    az_cli_login = function(...) {
      stop("az_cli_login should not be called when defining a chain")
    },
    .package = "azr"
  )

  chain <- default_credential_chain()

  expect_s3_class(chain, "credential_chain")
})

test_that("constructing AzureCLICredential performs no login check", {
  testthat::local_mocked_bindings(
    az_cli_is_login = function(...) {
      stop("az_cli_is_login should not be called at construction time")
    },
    .package = "azr"
  )

  spec <- credential_spec(AzureCLICredential)
  cred <- build_credential(spec, context = list(tenant_id = "test-tenant"))

  expect_s3_class(cred, "AzureCLICredential")
})

test_that("allow_interactive = FALSE prevents interactive credentials from being used", {
  chain <- credential_chain(device_code = DeviceCodeCredential)

  err <- tryCatch(
    get_credential_provider(chain = chain, allow_interactive = FALSE, verbose = FALSE),
    error = function(e) e
  )

  expect_match(conditionMessage(err), "interactive session")
})
