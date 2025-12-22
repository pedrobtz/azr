test_that("default_azure_tenant_id returns tenant ID from environment variable", {
  withr::local_envvar(AZURE_TENANT_ID = "my-custom-tenant-id")
  expect_equal(default_azure_tenant_id(), "my-custom-tenant-id")
})

test_that("default_azure_tenant_id returns default when environment variable not set", {
  withr::local_envvar(AZURE_TENANT_ID = NA)
  expect_equal(default_azure_tenant_id(), "common")
})

test_that("default_azure_tenant_id returns default when environment variable is empty", {
  withr::local_envvar(AZURE_TENANT_ID = NULL)
  expect_equal(default_azure_tenant_id(), "common")
})

test_that("default_azure_client_id returns client ID from environment variable", {
  withr::local_envvar(AZURE_CLIENT_ID = "my-custom-client-id")
  expect_equal(default_azure_client_id(), "my-custom-client-id")
})

test_that("default_azure_client_id returns default when environment variable not set", {
  withr::local_envvar(AZURE_CLIENT_ID = NA)
  expect_equal(
    default_azure_client_id(),
    "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
  )
})

test_that("default_azure_client_id returns default when environment variable is empty", {
  withr::local_envvar(AZURE_CLIENT_ID = NULL)
  expect_equal(
    default_azure_client_id(),
    "04b07795-8ddb-461a-bbee-02f9e1bf7b46"
  )
})

test_that("default_azure_client_secret returns client secret from environment variable", {
  withr::local_envvar(AZURE_CLIENT_SECRET = "my-secret-value")
  expect_equal(default_azure_client_secret(), "my-secret-value")
})

test_that("default_azure_client_secret returns NULL when environment variable not set", {
  withr::local_envvar(AZURE_CLIENT_SECRET = NA)
  expect_null(default_azure_client_secret())
})

test_that("default_azure_client_secret returns NULL when environment variable is empty", {
  withr::local_envvar(AZURE_CLIENT_SECRET = NULL)
  expect_null(default_azure_client_secret())
})

test_that("default_azure_scope returns default azure_arm scope", {
  expect_equal(default_azure_scope(), "https://management.azure.com/.default")
})

test_that("default_azure_scope returns azure_graph scope", {
  expect_equal(
    default_azure_scope("azure_graph"),
    "https://graph.microsoft.com/.default"
  )
})

test_that("default_azure_scope returns azure_storage scope", {
  expect_equal(
    default_azure_scope("azure_storage"),
    "https://storage.azure.com/.default"
  )
})

test_that("default_azure_scope returns azure_key_vault scope", {
  expect_equal(
    default_azure_scope("azure_key_vault"),
    "https://vault.azure.net/.default"
  )
})

test_that("default_azure_scope errors with invalid resource", {
  expect_error(default_azure_scope("invalid_resource"))
})

test_that("default_azure_oauth_client creates oauth_client with defaults", {
  withr::local_envvar(AZURE_CLIENT_ID = NA, AZURE_TENANT_ID = NA)
  client <- default_azure_oauth_client()

  expect_s3_class(client, "httr2_oauth_client")
  expect_equal(client$id, "04b07795-8ddb-461a-bbee-02f9e1bf7b46")
  expect_null(client$name)
  expect_null(client$secret)
  expect_equal(
    client$token_url,
    "https://login.microsoftonline.com/common/oauth2/v2.0/token"
  )
  expect_equal(client$auth, "oauth_client_req_auth_body")
})

test_that("default_azure_oauth_client creates oauth_client with custom client_id", {
  withr::local_envvar(AZURE_TENANT_ID = NA)
  client <- default_azure_oauth_client(client_id = "custom-client-id")

  expect_s3_class(client, "httr2_oauth_client")
  expect_equal(client$id, "custom-client-id")
  expect_null(client$secret)
})

test_that("default_azure_oauth_client creates oauth_client with client_secret", {
  withr::local_envvar(AZURE_CLIENT_ID = NA, AZURE_TENANT_ID = NA)
  client <- default_azure_oauth_client(client_secret = "my-secret")

  expect_s3_class(client, "httr2_oauth_client")
  expect_equal(client$secret, "my-secret")
})

test_that("default_azure_oauth_client creates oauth_client with custom name", {
  withr::local_envvar(AZURE_CLIENT_ID = NA, AZURE_TENANT_ID = NA)
  client <- default_azure_oauth_client(name = "my-app")

  expect_s3_class(client, "httr2_oauth_client")
  expect_equal(client$name, "my-app")
})

test_that("default_azure_oauth_client uses environment variables", {
  withr::local_envvar(
    AZURE_CLIENT_ID = "env-client-id",
    AZURE_TENANT_ID = "env-tenant-id"
  )
  client <- default_azure_oauth_client()

  expect_equal(client$id, "env-client-id")
  expect_equal(
    client$token_url,
    "https://login.microsoftonline.com/env-tenant-id/oauth2/v2.0/token"
  )
})

test_that("default_azure_host returns host from environment variable", {
  withr::local_envvar(AZURE_AUTHORITY_HOST = "login.microsoftonline.us")
  expect_equal(default_azure_host(), "login.microsoftonline.us")
})

test_that("default_azure_host returns default when environment variable not set", {
  withr::local_envvar(AZURE_AUTHORITY_HOST = NA)
  expect_equal(default_azure_host(), "login.microsoftonline.com")
})

test_that("default_azure_host returns default when environment variable is empty", {
  withr::local_envvar(AZURE_AUTHORITY_HOST = NULL)
  expect_equal(default_azure_host(), "login.microsoftonline.com")
})

test_that("default_azure_config_dir returns config dir from environment variable", {
  withr::local_envvar(AZURE_CONFIG_DIR = "/custom/azure/config")
  expect_equal(default_azure_config_dir(), "/custom/azure/config")
})

test_that("default_azure_config_dir returns Unix default when environment variable not set", {
  skip_on_os("windows")
  withr::local_envvar(AZURE_CONFIG_DIR = NA)
  expect_equal(default_azure_config_dir(), "~/.azure")
})

test_that("default_azure_config_dir returns Windows default when environment variable not set", {
  skip_on_os(c("mac", "linux", "solaris"))
  withr::local_envvar(
    AZURE_CONFIG_DIR = NA,
    USERPROFILE = "C:\\Users\\TestUser"
  )
  expect_equal(default_azure_config_dir(), "C:/Users/TestUser/.azure")
})

test_that("default_azure_config_dir returns default when environment variable is empty", {
  skip_on_os("windows")
  withr::local_envvar(AZURE_CONFIG_DIR = NULL)
  expect_equal(default_azure_config_dir(), "~/.azure")
})

test_that("default_azure_url returns all URLs as list when endpoint is NULL", {
  withr::local_envvar(AZURE_TENANT_ID = NA, AZURE_AUTHORITY_HOST = NA)
  urls <- default_azure_url()

  expect_type(urls, "list")
  expect_named(urls, c("authorize", "token", "devicecode"))
  expect_equal(
    urls$authorize,
    "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
  )
  expect_equal(
    urls$token,
    "https://login.microsoftonline.com/common/oauth2/v2.0/token"
  )
  expect_equal(
    urls$devicecode,
    "https://login.microsoftonline.com/common/oauth2/v2.0/devicecode"
  )
})

test_that("default_azure_url returns specific endpoint URL", {
  withr::local_envvar(AZURE_TENANT_ID = NA, AZURE_AUTHORITY_HOST = NA)
  expect_equal(
    default_azure_url("token"),
    "https://login.microsoftonline.com/common/oauth2/v2.0/token"
  )
  expect_equal(
    default_azure_url("authorize"),
    "https://login.microsoftonline.com/common/oauth2/v2.0/authorize"
  )
  expect_equal(
    default_azure_url("devicecode"),
    "https://login.microsoftonline.com/common/oauth2/v2.0/devicecode"
  )
})

test_that("default_azure_url uses custom tenant_id", {
  withr::local_envvar(AZURE_AUTHORITY_HOST = NA)
  url <- default_azure_url("token", tenant_id = "my-tenant-id")
  expect_equal(
    url,
    "https://login.microsoftonline.com/my-tenant-id/oauth2/v2.0/token"
  )
})

test_that("default_azure_url uses custom oauth_host", {
  withr::local_envvar(AZURE_TENANT_ID = NA)
  url <- default_azure_url("token", oauth_host = "login.microsoftonline.us")
  expect_equal(url, "https://login.microsoftonline.us/common/oauth2/v2.0/token")
})

test_that("default_azure_url uses environment variables", {
  withr::local_envvar(
    AZURE_TENANT_ID = "env-tenant",
    AZURE_AUTHORITY_HOST = "login.chinacloudapi.cn"
  )
  url <- default_azure_url("token")
  expect_equal(
    url,
    "https://login.chinacloudapi.cn/env-tenant/oauth2/v2.0/token"
  )
})

test_that("default_azure_url errors with invalid endpoint", {
  expect_error(default_azure_url("invalid_endpoint"))
})

test_that("default_redirect_uri adds random port when not present", {
  skip_if_not_installed("httpuv")
  uri <- default_redirect_uri("http://localhost")

  expect_match(uri, "^http://localhost:[0-9]+/$")
  parsed <- httr2::url_parse(uri)
  expect_false(is.null(parsed$port))
})

test_that("default_redirect_uri preserves existing port", {
  uri <- default_redirect_uri("http://localhost:8080/callback")

  expect_equal(uri, "http://localhost:8080/callback")
  parsed <- httr2::url_parse(uri)
  expect_equal(as.integer(parsed$port), 8080L)
})

test_that("default_redirect_uri uses httr2 default when not specified", {
  skip_if_not_installed("httpuv")
  uri <- default_redirect_uri()

  expect_type(uri, "character")
  expect_match(uri, "^http://")
  parsed <- httr2::url_parse(uri)
  expect_false(is.null(parsed$port))
})

test_that("is_port_available detects port availability", {
  skip_if_not_installed("httpuv")

  test_port <- 12345L

  # Port should be available initially
  expect_true(is_port_available(test_port, host = "0.0.0.0"))

  # Start a server to make the port unavailable
  server <- httpuv::startServer(
    host = "0.0.0.0",
    port = test_port,
    app = list(
      call = function(req) {
        list(status = 200L, headers = list("Content-Type" = "text/plain"), body = "test")
      }
    )
  )

  # Port should now be unavailable
  expect_false(is_port_available(test_port, host = "0.0.0.0"))

  # Stop the server
  httpuv::stopServer(server)

  # Port should be available again
  expect_true(is_port_available(test_port, host = "0.0.0.0"))
})

test_that("DefaultCredential can be instantiated with default arguments", {
  cred <- DefaultCredential$new()
  expect_s3_class(cred, "DefaultCredential")
  expect_s3_class(cred, "R6")
})

test_that("DefaultCredential stores initialization arguments", {
  cred <- DefaultCredential$new(
    scope = "https://graph.microsoft.com/.default",
    tenant_id = "my-tenant",
    client_id = "my-client",
    client_secret = "my-secret",
    use_cache = "memory",
    offline = FALSE
  )

  expect_equal(cred$.scope, "https://graph.microsoft.com/.default")
  expect_equal(cred$.tenant_id, "my-tenant")
  expect_equal(cred$.client_id, "my-client")
  expect_equal(cred$.client_secret, "my-secret")
  expect_equal(cred$.use_cache, "memory")
  expect_equal(cred$.offline, FALSE)
})

test_that("DefaultCredential has get_token and req_auth methods", {
  cred <- DefaultCredential$new()

  expect_true("get_token" %in% names(cred))
  expect_true("req_auth" %in% names(cred))
  expect_type(cred$get_token, "closure")
  expect_type(cred$req_auth, "closure")
})

test_that("DefaultCredential provider field is lazily evaluated", {
  withr::local_envvar(
    AZURE_CLIENT_SECRET = "test-secret"
  )

  cred <- DefaultCredential$new(
    scope = "https://management.azure.com/.default"
  )

  # Provider should be NULL initially (not yet accessed)
  expect_null(cred$.__enclos_env__$private$.provider_cache)

  # Accessing provider should trigger initialization
  # This will fail without valid credentials, but we can test the structure
  expect_error(provider <- cred$provider, class = "azr_credential_chain_failed")
})
