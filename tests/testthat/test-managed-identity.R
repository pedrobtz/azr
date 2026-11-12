# Construction ----

test_that("constructs with system-assigned identity by default", {
  cred <- new_mi_cred()
  expect_s3_class(cred, "ManagedIdentityCredential")
  expect_null(cred$.msi_client_id)
})

test_that("constructs with user-assigned identity (explicit client ID)", {
  cred <- new_mi_cred(managed_identity_client_id = "my-user-assigned-id")
  expect_equal(cred$.msi_client_id, "my-user-assigned-id")
})

test_that("managed_identity_client_id defaults to the azr option", {
  withr::local_envvar(AZR_MANAGED_IDENTITY_CLIENT_ID = "from-env")
  expect_equal(ManagedIdentityCredential$new()$.msi_client_id, "from-env")

  withr::local_options(azr.managed_identity_client_id = "from-option")
  expect_equal(ManagedIdentityCredential$new()$.msi_client_id, "from-option")
})

test_that("deprecated client_id argument still selects the identity", {
  expect_warning(
    cred <- ManagedIdentityCredential$new(client_id = "legacy-id"),
    class = "azr_deprecated_argument"
  )
  expect_equal(cred$.msi_client_id, "legacy-id")
})

test_that("unknown constructor arguments are rejected", {
  expect_error(
    ManagedIdentityCredential$new(tenant = "x"),
    class = "azr_managed_identity_unused_argument"
  )
})

test_that("chain context client_id is not forwarded as the managed identity", {
  withr::local_envvar(AZR_MANAGED_IDENTITY_CLIENT_ID = NA)
  seen <- new.env()
  local_mocked_bindings(
    mi_fetch_token = function(resource, client_id = NULL, ...) {
      seen$client_id <- client_id
      httr2::oauth_token(access_token = "mi_token", expires_in = 3600)
    }
  )

  cred <- get_credential_provider(
    scope = "https://management.azure.com/.default",
    client_id = "app-registration-id",
    chain = credential_chain(managed_identity = ManagedIdentityCredential)
  )

  expect_s3_class(cred, "ManagedIdentityCredential")
  expect_null(cred$.msi_client_id)
  expect_null(seen$client_id)
})

test_that(".msi_client_id is locked after initialize", {
  cred <- new_mi_cred()
  expect_error(
    cred$.msi_client_id <- "changed",
    class = "simpleError"
  )
})

test_that("resource gets trailing slash appended", {
  cred <- new_mi_cred()
  expect_true(endsWith(
    paste0(cred$.resource, "/"),
    "/"
  ))
})

# Token caching ----

test_that("get_token returns valid cached token without calling IMDS", {
  cred <- new_mi_cred()
  token <- httr2::oauth_token(
    access_token = "cached_mi_token",
    expires_in = 3600
  )
  mi_inject_token(cred, token)

  result <- cred$get_token()

  expect_identical(result$access_token, "cached_mi_token")
})

test_that("get_token calls IMDS when cache is empty", {
  cred <- new_mi_cred()
  fresh <- httr2::oauth_token(access_token = "fresh_token", expires_in = 3600)

  local_mocked_bindings(
    mi_fetch_token = function(...) fresh
  )

  result <- cred$get_token()
  expect_identical(result$access_token, "fresh_token")
})

test_that("get_token calls IMDS when cached token is expired", {
  cred <- new_mi_cred()
  expired <- httr2::oauth_token(access_token = "old_token", expires_in = 3600)
  expired$expires_at <- Sys.time() - 3600
  mi_inject_token(cred, expired)
  fresh <- httr2::oauth_token(access_token = "new_token", expires_in = 3600)

  local_mocked_bindings(
    mi_fetch_token = function(...) fresh
  )

  result <- cred$get_token()
  expect_identical(result$access_token, "new_token")
})

test_that("get_token stores fetched token in cache", {
  cred <- new_mi_cred()
  fresh <- httr2::oauth_token(access_token = "stored_token", expires_in = 3600)

  local_mocked_bindings(
    mi_fetch_token = function(...) fresh
  )

  cred$get_token()

  key <- rlang::hash(list(cred$.scope, cred$.msi_client_id))
  cached <- cred$.__enclos_env__$private$.token_cache[[key]]
  expect_identical(cached$access_token, "stored_token")
})

test_that("system and user-assigned identities use separate cache keys", {
  cred_sys <- new_mi_cred()
  cred_usr <- new_mi_cred(managed_identity_client_id = "user-id")

  sys_token <- httr2::oauth_token(access_token = "sys_token", expires_in = 3600)
  usr_token <- httr2::oauth_token(access_token = "usr_token", expires_in = 3600)

  mi_inject_token(cred_sys, sys_token)
  mi_inject_token(cred_usr, usr_token)

  expect_identical(cred_sys$get_token()$access_token, "sys_token")
  expect_identical(cred_usr$get_token()$access_token, "usr_token")
})

# mi_fetch_token ----

test_that("mi_fetch_token errors when IMDS is unreachable", {
  local_mocked_bindings(
    req_perform = function(...) stop("connection refused"),
    .package = "httr2"
  )

  expect_error(
    mi_fetch_token(resource = "https://management.azure.com/"),
    class = "azr_managed_identity_imds_error"
  )
})

test_that("mi_fetch_token errors on IMDS error response", {
  resp_body <- list(
    error = "invalid_request",
    error_description = "Identity not found"
  )

  local_mocked_bindings(
    req_perform = function(...) structure(list(), class = "httr2_response"),
    .package = "httr2"
  )
  local_mocked_bindings(mi_resp_body_json = function(...) resp_body)

  expect_error(
    mi_fetch_token(resource = "https://management.azure.com/"),
    class = "azr_managed_identity_token_error"
  )
})

test_that("mi_fetch_token returns oauth_token on success", {
  resp_body <- list(
    access_token = "imds_access_token",
    token_type = "Bearer",
    expires_in = "3600"
  )

  local_mocked_bindings(
    req_perform = function(...) structure(list(), class = "httr2_response"),
    .package = "httr2"
  )
  local_mocked_bindings(mi_resp_body_json = function(...) resp_body)

  token <- mi_fetch_token(resource = "https://management.azure.com/")

  expect_s3_class(token, "httr2_token")
  expect_identical(token$access_token, "imds_access_token")
})

# mi_resp_body_json ----

test_that("mi_resp_body_json wraps invalid JSON responses", {
  resp <- httr2::response(
    status_code = 502,
    url = "http://169.254.169.254/metadata/identity/oauth2/token",
    headers = list("content-type" = "text/html"),
    body = charToRaw("<html>bad gateway</html>")
  )

  expect_error(
    mi_resp_body_json(resp),
    class = "azr_managed_identity_invalid_json_response"
  )
})

test_that("mi_resp_body_json parses valid token JSON responses", {
  resp <- httr2::response(
    headers = list("content-type" = "application/json"),
    body = charToRaw('{"access_token":"abc","expires_in":3600}')
  )

  body <- mi_resp_body_json(resp)

  expect_equal(body$access_token, "abc")
  expect_equal(body$expires_in, 3600)
})

# default_credential_chain ----

test_that("default_credential_chain includes ManagedIdentityCredential", {
  chain <- default_credential_chain()
  nms <- names(chain)
  expect_true("managed_identity" %in% nms)
})

test_that("default_credential_chain includes WorkloadIdentityCredential", {
  chain <- default_credential_chain()
  nms <- names(chain)
  expect_true("workload_identity" %in% nms)
})

test_that("default_credential_chain orders azure_cli before interactive credentials", {
  chain <- default_credential_chain()
  nms <- names(chain)
  expect_lt(which(nms == "azure_cli"), which(nms == "auth_code"))
  expect_lt(which(nms == "azure_cli"), which(nms == "device_code"))
})

# Source detection ----

test_that("mi_detect_source falls back to IMDS without host variables", {
  local_mi_env()
  expect_equal(mi_detect_source(), "imds")
  expect_equal(new_mi_cred()$.msi_source, "imds")
})

test_that("mi_detect_source recognises each host", {
  local_mi_env(IDENTITY_ENDPOINT = "http://ep", IDENTITY_HEADER = "h")
  expect_equal(mi_detect_source(), "app_service")

  local_mi_env(IDENTITY_ENDPOINT = "http://ep", IMDS_ENDPOINT = "http://imds")
  expect_equal(mi_detect_source(), "azure_arc")

  local_mi_env(MSI_ENDPOINT = "http://ep", MSI_SECRET = "s")
  expect_equal(mi_detect_source(), "app_service_2017")

  local_mi_env(MSI_ENDPOINT = "http://ep")
  expect_equal(mi_detect_source(), "cloud_shell")

  local_mi_env(
    IDENTITY_ENDPOINT = "http://ep",
    IDENTITY_HEADER = "h",
    IDENTITY_SERVER_THUMBPRINT = "t"
  )
  expect_equal(mi_detect_source(), "service_fabric")
})

test_that("the detected source is locked and printed", {
  local_mi_env(IDENTITY_ENDPOINT = "http://ep", IDENTITY_HEADER = "h")
  cred <- new_mi_cred()
  expect_equal(cred$.msi_source, "app_service")
  expect_error(cred$.msi_source <- "imds", class = "simpleError")
  expect_match(cli::cli_fmt(print(cred)), "app_service", all = FALSE)
})

test_that("verbose chain output reports the managed identity source", {
  local_mi_env(IDENTITY_ENDPOINT = "http://ep", IDENTITY_HEADER = "h")
  local_mocked_bindings(
    mi_fetch_token = function(...) {
      httr2::oauth_token(access_token = "t", expires_in = 3600)
    }
  )

  msgs <- capture_messages(get_credential_provider(
    chain = credential_chain(managed_identity = ManagedIdentityCredential),
    verbose = TRUE
  ))
  expect_match(msgs, "managed identity source: \"app_service\"", all = FALSE)
})

test_that("get_token passes the detected source to mi_fetch_token", {
  local_mi_env(MSI_ENDPOINT = "http://ep", MSI_SECRET = "s")
  seen <- new.env()
  local_mocked_bindings(
    mi_fetch_token = function(resource, client_id = NULL, source = "imds") {
      seen$source <- source
      httr2::oauth_token(access_token = "t", expires_in = 3600)
    }
  )

  new_mi_cred()$get_token()
  expect_equal(seen$source, "app_service_2017")
})

# Token requests ----

test_that("IMDS request uses the metadata header and client_id", {
  req <- mi_token_request("imds", "https://management.azure.com/", "uami")
  url <- httr2::url_parse(httr2::req_get_url(req))

  expect_equal(url$hostname, "169.254.169.254")
  expect_equal(url$query$`api-version`, "2018-02-01")
  expect_equal(url$query$client_id, "uami")
  expect_equal(httr2::req_get_headers(req)$Metadata, "true")
})

test_that("App Service request uses IDENTITY_ENDPOINT and its header", {
  local_mi_env(
    IDENTITY_ENDPOINT = "http://localhost:8081/msi/token",
    IDENTITY_HEADER = "the-header"
  )
  req <- mi_token_request("app_service", "https://vault.azure.net/", "uami")
  url <- httr2::url_parse(httr2::req_get_url(req))

  expect_equal(url$path, "/msi/token")
  expect_equal(url$query$`api-version`, "2019-08-01")
  expect_equal(url$query$resource, "https://vault.azure.net/")
  expect_equal(url$query$client_id, "uami")
  headers <- httr2::req_get_headers(req, redacted = "reveal")
  expect_equal(headers$`X-IDENTITY-HEADER`, "the-header")
  expect_false(
    "the-header" %in% unlist(httr2::req_get_headers(req, redacted = "redact"))
  )
})

test_that("App Service 2017 request sends the secret and clientid", {
  local_mi_env(MSI_ENDPOINT = "http://localhost:8081/msi", MSI_SECRET = "s3")
  req <- mi_token_request("app_service_2017", "https://vault.azure.net/", "u")
  url <- httr2::url_parse(httr2::req_get_url(req))

  expect_equal(url$query$`api-version`, "2017-09-01")
  expect_equal(url$query$clientid, "u")
  expect_null(url$query$client_id)
  expect_equal(httr2::req_get_headers(req, redacted = "reveal")$secret, "s3")
})

test_that("Cloud Shell request posts the resource as a form", {
  local_mi_env(MSI_ENDPOINT = "http://localhost:50342/oauth2/token")
  req <- mi_token_request("cloud_shell", "https://vault.azure.net/")

  expect_equal(httr2::req_get_method(req), "POST")
  expect_equal(httr2::req_get_body_type(req), "form")
  expect_equal(
    utils::URLdecode(httr2::req_get_body(req)$resource),
    "https://vault.azure.net/"
  )
})

test_that("Azure Arc request uses the 2020-06-01 API", {
  local_mi_env(
    IDENTITY_ENDPOINT = "http://localhost:40342/metadata/identity/oauth2/token",
    IMDS_ENDPOINT = "http://localhost:40342"
  )
  req <- mi_token_request("azure_arc", "https://vault.azure.net/")
  url <- httr2::url_parse(httr2::req_get_url(req))

  expect_equal(as.integer(url$port), 40342L)
  expect_equal(url$query$`api-version`, "2020-06-01")
})

test_that("unsupported sources and identities fail with classed errors", {
  expect_error(
    mi_fetch_token("https://vault.azure.net/", source = "service_fabric"),
    class = "azr_managed_identity_unsupported_source"
  )
  expect_error(
    mi_fetch_token("https://vault.azure.net/", "uami", source = "azure_arc"),
    class = "azr_managed_identity_unsupported_user_assigned"
  )
  expect_error(
    mi_fetch_token("https://vault.azure.net/", "uami", source = "cloud_shell"),
    class = "azr_managed_identity_unsupported_user_assigned"
  )
})

test_that("an unreachable local endpoint raises the endpoint error class", {
  local_mi_env(IDENTITY_ENDPOINT = "http://ep", IDENTITY_HEADER = "h")
  local_mocked_bindings(
    req_perform = function(...) stop("connection refused"),
    .package = "httr2"
  )

  err <- expect_error(
    mi_fetch_token("https://vault.azure.net/", source = "app_service"),
    class = "azr_managed_identity_endpoint_error"
  )
  expect_false(inherits(err, "azr_managed_identity_imds_error"))
})

test_that("App Service tokens take their expiry from expires_on", {
  local_mi_env(IDENTITY_ENDPOINT = "http://ep", IDENTITY_HEADER = "h")
  expires_on <- as.character(as.integer(Sys.time()) + 1800L)
  local_mocked_bindings(
    mi_perform = function(req, source) {
      mi_json_response(list(
        access_token = "as_token",
        expires_on = expires_on,
        token_type = "Bearer"
      ))
    }
  )

  token <- mi_fetch_token("https://vault.azure.net/", source = "app_service")

  expect_identical(token$access_token, "as_token")
  expect_equal(token$expires_at, as.numeric(expires_on), tolerance = 2)
})

test_that("token errors in the App Service object format are reported", {
  local_mocked_bindings(
    mi_perform = function(req, source) {
      mi_json_response(
        list(error = list(code = "Forbidden", message = "No identity")),
        status = 400L
      )
    }
  )

  expect_error(
    mi_fetch_token("https://vault.azure.net/", source = "imds"),
    class = "azr_managed_identity_token_error"
  )
})

# Azure Arc challenge ----

test_that("Azure Arc answers the challenge with the key file", {
  key_dir <- withr::local_tempdir()
  key_file <- file.path(key_dir, "abc.key")
  writeLines("secret-key", key_file, sep = "")
  local_mi_env(
    IDENTITY_ENDPOINT = "http://localhost:40342/metadata/identity/oauth2/token",
    IMDS_ENDPOINT = "http://localhost:40342"
  )

  calls <- list()
  local_mocked_bindings(
    mi_arc_key_dir = function() key_dir,
    mi_perform = function(req, source) {
      calls[[length(calls) + 1L]] <<- req
      if (length(calls) == 1L) {
        mi_json_response(
          list(error = "unauthorized"),
          status = 401L,
          headers = list(`WWW-Authenticate` = paste0("Basic realm=", key_file))
        )
      } else {
        mi_json_response(list(access_token = "arc_token", expires_in = "3600"))
      }
    }
  )

  token <- mi_fetch_token("https://vault.azure.net/", source = "azure_arc")

  expect_identical(token$access_token, "arc_token")
  expect_length(calls, 2L)
  auth <- httr2::req_get_headers(calls[[2]], redacted = "reveal")$Authorization
  expect_equal(auth, "Basic secret-key")
})

test_that("Azure Arc rejects a key file outside the agent directory", {
  key_dir <- withr::local_tempdir()
  other <- withr::local_tempfile(fileext = ".key", lines = "k")
  local_mocked_bindings(mi_arc_key_dir = function() key_dir)

  resp <- mi_json_response(
    list(),
    status = 401L,
    headers = list(`WWW-Authenticate` = paste0("Basic realm=", other))
  )
  expect_error(mi_arc_read_key(resp), class = "azr_managed_identity_arc_error")
})

test_that("Azure Arc rejects a missing realm, a wrong extension and a big key", {
  key_dir <- withr::local_tempdir()
  local_mocked_bindings(mi_arc_key_dir = function() key_dir)
  challenge <- function(path) {
    mi_json_response(
      list(),
      status = 401L,
      headers = list(`WWW-Authenticate` = paste0("Basic realm=", path))
    )
  }

  expect_error(
    mi_arc_read_key(mi_json_response(list(), status = 401L)),
    class = "azr_managed_identity_arc_error"
  )

  txt <- file.path(key_dir, "abc.txt")
  writeLines("k", txt)
  expect_error(
    mi_arc_read_key(challenge(txt)),
    class = "azr_managed_identity_arc_error"
  )

  big <- file.path(key_dir, "big.key")
  writeLines(strrep("k", 5000L), big)
  expect_error(
    mi_arc_read_key(challenge(big)),
    class = "azr_managed_identity_arc_error"
  )
})

# Expiry parsing ----

test_that("mi_expires_in reads each endpoint's expiry format", {
  now <- as.POSIXct("2017-09-14 10:00:00", tz = "UTC")

  expect_equal(mi_expires_in(list(expires_in = "3599"), now), 3599)
  expect_equal(
    mi_expires_in(list(expires_on = as.character(as.numeric(now) + 60)), now),
    60
  )
  expect_equal(
    mi_expires_in(list(expires_on = "09/14/2017 01:00:00 PM +00:00"), now),
    3 * 3600
  )
  expect_equal(
    mi_expires_in(list(expires_on = "09/14/2017 11:00:00 +00:00"), now),
    3600
  )
})

test_that("mi_expires_in assumes an hour when expiry is missing or unreadable", {
  expect_equal(mi_expires_in(list()), 3600)
  expect_equal(mi_expires_in(list(expires_on = "soon")), 3600)
})
