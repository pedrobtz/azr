#' Azure CLI credential authentication
#'
#' @description
#' Authenticates using the Azure CLI (`az`) command-line tool. This credential
#' requires the Azure CLI to be installed and the user to be logged in via
#' `az login`.
#'
#' @details
#' The credential uses the `az account get-access-token` command to retrieve
#' access tokens. It will use the currently active Azure CLI account and
#' subscription unless a specific tenant is specified.
#'
#' @export
#' @examples
#' # Create credential with default settings
#' cred <- AzureCLICredential$new()
#'
#' # Create credential with specific scope and tenant
#' cred <- AzureCLICredential$new(
#'   scope = "https://management.azure.com/.default",
#'   tenant_id = "your-tenant-id"
#' )
#'
#' # To get a token or authenticate a request it is required that
#' # 'az login' is successfully executed, otherwise it will return an error.
#' \dontrun{
#' # Get an access token
#' token <- cred$get_token()
#'
#' # Use with httr2 request
#' req <- httr2::request("https://management.azure.com/subscriptions")
#' resp <- httr2::req_perform(cred$req_auth(req))
#' }
AzureCLICredential <- R6::R6Class(
  classname = "AzureCLICredential",
  inherit = Credential,
  public = list(
    #' @field interactive Logical indicating whether to check login status and
    #'   perform login if needed
    interactive = FALSE,
    #' @field .process_timeout Timeout in seconds for Azure CLI command execution
    .process_timeout = 10,

    #' @description
    #' Create a new Azure CLI credential
    #'
    #' @param scope A character string specifying the OAuth2 scope. Defaults to
    #'   `NULL`, which uses the scope set during initialization.
    #' @param tenant_id A character string specifying the Azure Active Directory
    #'   tenant ID. Defaults to `NULL`, which uses the default tenant from Azure CLI.
    #' @param process_timeout A numeric value specifying the timeout in seconds
    #'   for the Azure CLI process. Defaults to `10`.
    #' @param interactive A logical value indicating whether to check if the user is
    #'   logged in and perform login if needed. Defaults to `FALSE`.
    #' @param use_bridge A logical value indicating whether to use the device code
    #'   bridge webpage during login. If `TRUE`, launches an intermediate local webpage
    #'   that displays the device code and facilitates copy-pasting before redirecting
    #'   to the Microsoft device login page. Only used when `interactive = TRUE`. Defaults to `FALSE`.
    #'
    #' @return A new `AzureCLICredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      process_timeout = NULL,
      interactive = FALSE,
      use_bridge = FALSE
    ) {
      self$interactive <- interactive
      super$initialize(
        scope = scope,
        tenant_id = tenant_id
      )
      self$.process_timeout <- process_timeout %||% self$.process_timeout

      if (isTRUE(self$is_interactive())) {
        # Check if user is logged in
        if (!az_cli_is_login(timeout = self$.process_timeout)) {
          cli::cli_alert_info("User is not logged in to Azure CLI")
          az_cli_login(use_bridge = use_bridge)
        }
      }
    },
    #' @description
    #' Get an access token from Azure CLI
    #'
    #' @param scope A character string specifying the OAuth2 scope. If `NULL`,
    #'   uses the scope specified during initialization.
    #'
    #' @return An [httr2::oauth_token()] object containing the access token
    get_token = function(scope = NULL) {
      # Check if user is logged in
      if (!az_cli_is_login(timeout = self$.process_timeout)) {
        cli::cli_abort(
          c(
            "User is not logged in to Azure CLI",
            "i" = "Please run {.code $login()} or use {.code az login} in your terminal"
          ),
          class = "azr_cli_not_logged_in"
        )
      }

      rlang::try_fetch(
        az_cli_get_token(
          scope = scope %||% self$.scope,
          tenant_id = self$.tenant_id,
          timeout = self$.process_timeout
        ),
        error = function(cnd) {
          cli::cli_abort(cnd$message, call = call("get_token"))
        }
      )
    },
    #' @description
    #' Add authentication to an httr2 request
    #'
    #' @param req An [httr2::request()] object
    #' @param scope A character string specifying the OAuth2 scope. If `NULL`,
    #'   uses the scope specified during initialization.
    #'
    #' @return The request object with authentication header added
    req_auth = function(req, scope = NULL) {
      # Check if user is logged in
      if (!az_cli_is_login(timeout = self$.process_timeout)) {
        cli::cli_abort(
          c(
            "User is not logged in to Azure CLI",
            "i" = "Please run {.code $login()} or use {.code az login} in your terminal"
          ),
          class = "azr_cli_not_logged_in"
        )
      }

      token <- self$get_token(scope)
      httr2::req_auth_bearer_token(req, token$access_token)
    },
    #' @description
    #' Show the currently active Azure CLI account information
    #'
    #' @param timeout A numeric value specifying the timeout in seconds for the
    #'   Azure CLI command. If `NULL`, uses the process timeout specified during
    #'   initialization.
    #'
    #' @return A list containing the account information from Azure CLI
    account_show = function(timeout = NULL) {
      az_cli_account_show(timeout = timeout %||% self$.process_timeout)
    },
    #' @description
    #' Perform Azure CLI login using device code flow
    #'
    #' @return Invisibly returns the exit status (0 for success, non-zero for failure)
    login = function() {
      az_cli_login()
    },
    #' @description
    #' Check if the credential requires user interaction
    #'
    #' @return Logical indicating whether this credential is interactive
    is_interactive = function() {
      self$interactive
    },
    #' @description
    #' Log out from Azure CLI
    #'
    #' @return Invisibly returns `NULL`
    logout = function() {
      az_cli_logout()
    }
  )
)


#' Get Access Token from Azure CLI
#'
#' @description
#' Retrieves an access token from Azure CLI using the `az account get-access-token`
#' command. This is a lower-level function that directly interacts with the Azure
#' CLI to obtain OAuth2 tokens.
#'
#' @details
#' This function executes the Azure CLI command and parses the JSON response to
#' create an httr2 OAuth token object. The token includes the access token,
#' token type, and expiration time.
#'
#' @param scope A character string specifying the OAuth2 scope for which to
#'   request the access token (e.g., `"https://management.azure.com/.default"`).
#' @param tenant_id A character string specifying the Azure Active Directory
#'   tenant ID. If `NULL`, uses the default tenant from Azure CLI. Defaults to `NULL`.
#' @param timeout A numeric value specifying the timeout in seconds for the
#'   Azure CLI process. Defaults to `10`.
#'
#' @return An [httr2::oauth_token()] object containing:
#'   - `access_token`: The OAuth2 access token string
#'   - `token_type`: The type of token (typically "Bearer")
#'   - `.expires_at`: POSIXct timestamp when the token expires
#'
#' @export
az_cli_get_token <- function(scope, tenant_id = NULL, timeout = 10L) {
  args <- c("account", "get-access-token", "--output", "json")
  az_path <- az_cli_available()

  validate_scope(scope)
  args <- append(args, c("--scope", scope))

  if (!is.null(tenant_id)) {
    validate_tenant_id(tenant_id)
    args <- append(args, c("--tenant", tenant_id))
  }

  output <- suppressWarnings(system2(
    command = az_path,
    args = args,
    stdout = TRUE,
    stderr = TRUE,
    timeout = timeout
  ))

  status <- attr(output, "status")

  # Check for command failure
  if (!is.null(status) && status != 0L) {
    if (status == 124L) {
      cli::cli_abort(
        sprintf("Azure CLI command timed out after %d seconds", timeout),
        class = "azr_cli_timeout_error"
      )
    }

    # Provide context with the error
    error_msg <- paste(output, collapse = "\n")
    cli::cli_abort(
      sprintf("Azure CLI command failed (exit code %d): %s", status, error_msg),
      class = "azr_cli_error"
    )
  }

  # Check for empty output
  if (length(output) == 0 || !nzchar(paste(output, collapse = ""))) {
    cli::cli_abort(
      "Azure CLI returned empty output. Ensure you are logged in with 'az login'",
      class = "azr_cli_empty_output"
    )
  }

  # Parse JSON with error handling
  token <- tryCatch(
    jsonlite::fromJSON(paste(output, collapse = "\n")),
    error = function(e) {
      cli::cli_abort(
        sprintf("Failed to parse Azure CLI output as JSON: %s", e$message),
        class = "azr_cli_parse_error"
      )
    }
  )

  # Validate required fields
  required_fields <- c("accessToken", "tokenType", "expiresOn")
  missing_fields <- setdiff(required_fields, names(token))

  if (length(missing_fields) > 0) {
    cli::cli_abort(
      sprintf(
        "Azure CLI response missing required fields: %s",
        paste(missing_fields, collapse = ", ")
      ),
      class = "azr_cli_invalid_response"
    )
  }

  expires_at <- as.POSIXct(token$expiresOn)

  token_info <- tryCatch(
    find_msal_token(access_token = token$accessToken),
    error = function(e) NULL
  )

  token_args <- list(
    access_token = token$accessToken,
    token_type = token$tokenType,
    expires_at = expires_at
  )
  if (!is.null(token_info[["refresh_token"]])) {
    token_args$refresh_token <- token_info[["refresh_token"]]
  }
  if (!is.null(token_info[["scope"]])) {
    token_args$scope <- token_info[["scope"]]
  }

  do.call(httr2::oauth_token, token_args)
}


az_cli_available <- function() {
  az_path <- Sys.which("az")

  if (!nzchar(az_path)) {
    cli::cli_abort(
      c(
        "Azure CLI not found on PATH",
        "i" = "Install Azure CLI: https://docs.microsoft.com/cli/azure/install-azure-cli",
        "i" = "Or ensure 'az' is in your system PATH"
      ),
      class = "azr_cli_not_found"
    )
  }

  az_path
}


#' Check if User is Logged in to Azure CLI
#'
#' @description
#' Checks whether the user is currently logged in to Azure CLI by attempting
#' to retrieve account information.
#'
#' @param timeout A numeric value specifying the timeout in seconds for the
#'   Azure CLI command. Defaults to `10`.
#'
#' @return A logical value: `TRUE` if the user is logged in, `FALSE` otherwise
#'
#' @export
az_cli_is_login <- function(timeout = 10L) {
  tryCatch(
    {
      az_cli_account_show(timeout = timeout)
      TRUE
    },
    error = function(e) {
      FALSE
    }
  )
}


#' Azure CLI Device Code Login
#'
#' @description
#' Performs an interactive Azure CLI login using device code flow.
#' Automatically captures the device code, copies it to the clipboard,
#' and opens the browser for authentication.
#'
#' @details
#' This function runs `az login --use-device-code`, monitors the output
#' to extract the device code, copies it to the clipboard, and opens
#' the authentication URL in the default browser.
#'
#' @param tenant_id A character string specifying the Azure Active Directory
#'   tenant ID to authenticate against. If `NULL` (default), uses the default
#'   tenant from Azure CLI configuration.
#' @param use_bridge A logical value indicating whether to use the device code
#'   bridge webpage. If `TRUE`, launches an intermediate local webpage that
#'   displays the device code and facilitates copy-pasting before redirecting
#'   to the Microsoft device login page. If `FALSE` (default), copies the code
#'   directly to the clipboard and opens the Microsoft login page.
#' @param verbose A logical value indicating whether to print detailed process
#'   output to the console, including error messages from the Azure CLI process.
#'   If `FALSE` (default), only essential messages are displayed.
#'
#' @return Invisibly returns the exit status (0 for success, non-zero for failure)
#'
#' @export
az_cli_login <- function(
  tenant_id = NULL,
  use_bridge = FALSE,
  verbose = FALSE
) {
  if (!rlang::is_interactive()) {
    cli::cli_abort(
      c(
        "Azure CLI login requires an interactive session",
        "i" = "This function cannot be used in non-interactive environments"
      ),
      class = "azr_cli_non_interactive"
    )
  }

  az_path <- az_cli_available()
  az_args <- c("login", "--use-device-code", "--output", "json")

  if (!is.null(tenant_id)) {
    validate_tenant_id(tenant_id)
    az_args <- c(az_args, c("--tenant", tenant_id))
  }

  cli::cli_alert_info("Starting Azure CLI login process...")

  output_file <- tempfile(fileext = ".json")

  rlang::check_installed("processx")

  # Start the process in the background
  p <- processx::process$new(
    az_path,
    az_args,
    stdout = output_file,
    stderr = "|"
  )

  # Variables to track state
  code_found <- FALSE
  login_url <- "https://microsoft.com/devicelogin"
  all_stdout <- character()

  # Loop to read output while the process is alive
  while (p$is_alive()) {
    # Poll for output (wait up to 100ms)
    p$poll_io(100)

    # Read stdout and stderr
    lines_err <- p$read_error_lines()

    # Collect stdout for later parsing
    if (length(lines_err) > 0) {
      all_stdout <- c(all_stdout, lines_err)
    }

    # Print output to console
    if (isTRUE((verbose) && lines_err) > 0) {
      cli::cli_alert_warning("Error output:")
      for (line in lines_err) {
        cli::cli_text(line)
      }
    }

    # Look for the device code
    if (!code_found && length(lines_err) > 0) {
      # Combine lines to handle wrapping
      combined_text <- paste(lines_err, collapse = " ")

      # Look for the code pattern (usually 9 alphanumeric characters)
      match <- regexec(
        "enter the code ([A-Z0-9]+) to authenticate",
        combined_text
      )
      match_text <- regmatches(combined_text, match)[[1]]

      if (length(match_text) > 1) {
        device_code <- match_text[2]
        code_found <- TRUE

        cli::cli_alert_success("Found Device Code: {.val {device_code}}")

        if (isTRUE(use_bridge)) {
          tryCatch(
            {
              launch_device_code(device_code)
              cli::cli_alert_info(
                "Launch web bridge to copy code to clipboard!"
              )
            },
            error = function(e) {
              cli::cli_alert_warning(
                "Could not use browser. Please copy manually."
              )
            }
          )
        } else {
          # Copy to clipboard
          rlang::check_installed("clipr")
          tryCatch(
            {
              clipr::write_clip(device_code)
              cli::cli_alert_info("Code copied to clipboard! [Cmd/Ctrl + V]")
            },
            error = function(e) {
              cli::cli_alert_warning(
                "Could not write to clipboard. Please copy manually."
              )
            }
          )

          cli::cli_alert_info("Opening browser to {.url {login_url}}...")
          utils::browseURL(login_url)
        }
      }
    }

    # Sleep briefly to prevent 100% CPU usage
    Sys.sleep(0.1)
  }

  # Check exit status
  exit_status <- p$get_exit_status()
  error_lines <- p$read_error_lines()

  # Print any remaining error lines
  if (isTRUE(verbose) && length(error_lines) > 0) {
    cli::cli_alert_warning("Error output:")
    for (line in error_lines) {
      cli::cli_text(line)
    }
  }

  if (exit_status == 0) {
    cli::cli_alert_success("Login Completed Successfully!")

    result <- tryCatch(
      jsonlite::fromJSON(output_file),
      error = function(e) {
        NULL
      }
    )
    return(invisible(result))
  } else {
    cli::cli_alert_danger("Process finished with error (Status: {exit_status})")
  }

  invisible(exit_status)
}


#' Show Azure CLI Account Information
#'
#' @description
#' Retrieves information about the currently active Azure CLI account and
#' subscription. This function runs `az account show` and parses the JSON
#' output into an R list.
#'
#' @details
#' The function returns details about the current Azure subscription including:
#' - Subscription ID and name
#' - Tenant ID
#' - Account state (e.g., "Enabled")
#' - User information
#' - Cloud environment details
#'
#' @param timeout An integer specifying the timeout in seconds for the Azure
#'   CLI command. Defaults to `10`.
#'
#' @return A list containing the account information from Azure CLI
#'
#' @export
az_cli_account_show <- function(timeout = 10L) {
  az_path <- az_cli_available()
  args <- c("account", "show", "--output", "json")

  output <- suppressWarnings(system2(
    command = az_path,
    args = args,
    stdout = TRUE,
    stderr = TRUE,
    timeout = timeout
  ))

  status <- attr(output, "status")

  # Check for command failure
  if (!is.null(status) && status != 0L) {
    if (status == 124L) {
      cli::cli_abort(
        sprintf("Azure CLI command timed out after %d seconds", timeout),
        class = "azr_cli_timeout_error"
      )
    }

    # Provide context with the error
    error_msg <- paste(output, collapse = "\n")
    cli::cli_abort(
      sprintf("Azure CLI command failed (exit code %d): %s", status, error_msg),
      class = "azr_cli_error"
    )
  }

  # Check for empty output
  if (length(output) == 0 || !nzchar(paste(output, collapse = ""))) {
    cli::cli_abort(
      "Azure CLI returned empty output. Ensure you are logged in with 'az login'",
      class = "azr_cli_empty_output"
    )
  }

  # Parse JSON with error handling
  account_info <- tryCatch(
    jsonlite::fromJSON(paste(output, collapse = "\n")),
    error = function(e) {
      cli::cli_abort(
        sprintf("Failed to parse Azure CLI output as JSON: %s", e$message),
        class = "azr_cli_parse_error"
      )
    }
  )

  return(account_info)
}


#' Azure CLI Logout
#'
#' @description
#' Logs out from Azure CLI by removing all stored credentials and account
#' information. This function runs `az logout`.
#'
#' @details
#' After logging out, you will need to run [az_cli_login()] again to
#' authenticate and use Azure CLI credentials.
#'
#' @return Invisibly returns `NULL`
#'
#' @export
az_cli_logout <- function() {
  az_path <- az_cli_available()
  args <- c("logout")

  cli::cli_alert_info("Logging out from Azure CLI...")

  output <- suppressWarnings(system2(
    command = az_path,
    args = args,
    stdout = TRUE,
    stderr = TRUE
  ))

  status <- attr(output, "status")

  if (!is.null(status) && status != 0L) {
    error_msg <- paste(output, collapse = "\n")

    cli::cli_bullets(c(
      c(
        "!" = "Azure CLI logout failed (exit code {.val {status}})",
        "x" = error_msg
      )
    ))
  } else {
    cli::cli_alert_success("Successfully logged out from Azure CLI")
  }

  invisible(NULL)
}


#' Write an httr2 Token to the MSAL Token Cache
#'
#' @description
#' Writes an [httr2::oauth_token()] object into the MSAL token cache JSON file
#' (`msal_token_cache.json`) shared by the Azure SDK and Azure CLI. The
#' resulting entry is readable by other Azure tools (Python SDK, Azure CLI,
#' and the rest of this package via [az_cli_get_cached_token()]).
#'
#' @details
#' The function adds or overwrites `AccessToken`, `RefreshToken` (when the
#' token carries a refresh token), `Account`, and `AppMetadata` sections.
#' Existing entries for other accounts or clients are preserved.
#'
#' The `home_account_id` follows the MSAL convention
#' `"<object_id>.<tenant_id>"` where `object_id` is the Azure AD OID of the
#' authenticated principal. Cache entry keys are built in the same format used
#' by the Azure CLI and MSAL Python:
#' \itemize{
#'   \item AccessToken: `<home_account_id>-<environment>-accesstoken-<client_id>-<realm>-<target>`
#'   \item RefreshToken: `<home_account_id>-<environment>-refreshtoken-<client_id>--`
#'   \item Account: `<home_account_id>-<environment>-<realm>`
#'   \item AppMetadata: `appmetadata-<environment>-<client_id>`
#' }
#'
#' @param token An [httr2::oauth_token()] object. Must contain `access_token`,
#'   `token_type`, and `.expires_at`. May optionally contain `refresh_token`
#'   and `scope`. All cache fields (`home_account_id`, `tenant_id`, `username`,
#'   `client_id`, `scope`, `environment`) are derived from the JWT claims
#'   (`oid`, `tid`, `upn`/`preferred_username`, `appid`/`azp`, `scp`/`scope`,
#'   `iss`) and the token object itself.
#' @param cache_file Path to the MSAL token cache JSON file. Defaults to
#'   [default_msal_token_cache()].
#'
#' @return Invisibly returns the path to the cache file.
#'
#' @seealso [az_cli_get_cached_token()], [httr2::oauth_token()]
#'
#' @export
write_msal_token <- function(
  token,
  cache_file = default_msal_token_cache()
) {
  fields <- extract_msal_token_fields(token)
  cache <- build_msal_cache_entries(token, fields, cache_file)
  write_msal_cache(cache, cache_file)
}

# Extracts and validates identity fields from an httr2_token object by decoding
# its JWT access token claims.
extract_msal_token_fields <- function(token) {
  if (!inherits(token, "httr2_token")) {
    cli::cli_abort(
      "{.arg token} must be an {.cls httr2_token} object, not {.cls {class(token)[[1L]]}}.",
      call = rlang::caller_env()
    )
  }

  claims <- decode_jwt_claims(token$access_token)

  oid <- claims[["oid"]]
  tid <- claims[["tid"]]
  client_id <- claims[["appid"]] %||% claims[["azp"]]
  if (is.null(oid) || is.null(tid) || is.null(client_id)) {
    missing <- names(Filter(
      is.null,
      list(oid = oid, tid = tid, appid = client_id)
    ))
    cli::cli_abort(
      c(
        "Cannot derive account identity from the access token.",
        "i" = "The JWT is missing {.field {missing}} claim{?s}."
      )
    )
  }

  home_account_id <- paste0(oid, ".", tid)

  iss <- claims[["iss"]]
  environment <- if (!is.null(iss)) {
    host <- sub("^https?://", "", iss)
    sub("/.*$", "", host)
  } else {
    host <- sub("^https?://", "", default_azure_host())
    sub("/$", "", host)
  }

  list(
    home_account_id = home_account_id,
    local_account_id = oid,
    tenant_id = tid,
    client_id = client_id,
    username = claims[["upn"]] %||% claims[["preferred_username"]],
    environment = environment,
    scope_str = paste(token$scope %||% character(0L), collapse = " ")
  )
}

# Merges new MSAL cache entries built from a token and its extracted fields into
# an existing cache list (read from disk if present).
build_msal_cache_entries <- function(token, fields, cache_file) {
  now_unix <- as.character(as.integer(Sys.time()))
  expires_unix <- as.character(as.integer(token$.expires_at))
  ext_expires <- as.character(as.integer(token$.expires_at) + 86400L)

  # All key components are lowercased per MSAL convention
  env_l <- tolower(fields$environment)
  client_l <- tolower(fields$client_id)
  realm_l <- tolower(fields$tenant_id)
  acct_l <- tolower(fields$home_account_id)
  target_l <- tolower(fields$scope_str)

  at_key <- paste(
    acct_l,
    env_l,
    "accesstoken",
    client_l,
    realm_l,
    target_l,
    sep = "-"
  )
  # Refresh token key has empty family_id and empty target, producing double trailing dash
  rt_key <- paste(acct_l, env_l, "refreshtoken", client_l, "", "", sep = "-")
  account_key <- paste(acct_l, env_l, realm_l, sep = "-")
  app_key <- paste("appmetadata", env_l, client_l, sep = "-")

  cache <- if (file.exists(cache_file)) {
    tryCatch(read_msal_cache(cache_file), error = function(e) list())
  } else {
    list()
  }

  for (section in c(
    "AccessToken",
    "RefreshToken",
    "IdToken",
    "Account",
    "AppMetadata"
  )) {
    if (is.null(cache[[section]])) cache[[section]] <- list()
  }

  cache$AccessToken[[at_key]] <- list(
    home_account_id = fields$home_account_id,
    environment = fields$environment,
    client_id = fields$client_id,
    target = fields$scope_str,
    realm = fields$tenant_id,
    token_type = token$token_type %||% "Bearer",
    cached_at = now_unix,
    expires_on = expires_unix,
    extended_expires_on = ext_expires,
    secret = token$access_token,
    credential_type = "AccessToken"
  )

  if (nzchar(token$refresh_token %||% "")) {
    cache$RefreshToken[[rt_key]] <- list(
      home_account_id = fields$home_account_id,
      environment = fields$environment,
      client_id = fields$client_id,
      target = fields$scope_str,
      secret = token$refresh_token,
      credential_type = "RefreshToken"
    )
  }

  acct_entry <- list(
    home_account_id = fields$home_account_id,
    environment = fields$environment,
    realm = fields$tenant_id,
    authority_type = "MSSTS",
    local_account_id = fields$local_account_id
  )
  if (!is.null(fields$username)) {
    acct_entry$username <- fields$username
  }
  cache$Account[[account_key]] <- acct_entry

  cache$AppMetadata[[app_key]] <- list(
    client_id = fields$client_id,
    environment = fields$environment
  )

  cache
}

# Serialises a cache list to the MSAL JSON cache file, creating parent
# directories as needed.
write_msal_cache <- function(cache, cache_file) {
  cache_dir <- dirname(cache_file)
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
  }
  jsonlite::write_json(cache, cache_file, pretty = TRUE, auto_unbox = TRUE)
  invisible(cache_file)
}


# Reads and parses the MSAL token cache JSON file. Aborts if the file does not
# exist or cannot be parsed.
read_msal_cache <- function(cache_file) {
  if (!file.exists(cache_file)) {
    cli::cli_abort(
      c(
        "MSAL token cache file not found.",
        "i" = "Expected file at: {.path {cache_file}}"
      ),
      class = "azr_cli_cache_not_found_error"
    )
  }
  tryCatch(
    jsonlite::fromJSON(cache_file, simplifyDataFrame = FALSE),
    error = function(e) {
      cli::cli_abort(
        c(
          "Failed to parse MSAL token cache: {e$message}",
          "i" = "The cache file may be corrupted: {.path {cache_file}}"
        ),
        class = "azr_cli_cache_parse_error"
      )
    }
  )
}

# Decodes the payload of a JWT (without verifying the signature) and returns
# the claims as a named list. Returns an empty list if the token is not a
# well-formed JWT.
decode_jwt_claims <- function(jwt) {
  parts <- strsplit(jwt, ".", fixed = TRUE)[[1L]]
  if (length(parts) < 2L) {
    return(list())
  }
  payload <- parts[[2L]]
  # base64url -> base64: replace chars and add padding
  payload <- gsub("-", "+", payload, fixed = TRUE)
  payload <- gsub("_", "/", payload, fixed = TRUE)
  pad <- (4L - nchar(payload) %% 4L) %% 4L
  payload <- paste0(payload, strrep("=", pad))
  tryCatch(
    jsonlite::fromJSON(
      rawToChar(jsonlite::base64_dec(payload)),
      simplifyDataFrame = FALSE
    ),
    error = function(e) list()
  )
}

# Reads the MSAL token cache JSON and returns a list with `refresh_token` and
# `scope` matching the given credentials. If `access_token` is provided its
# value is matched against the `secret` field of every `AccessToken` entry to
# resolve `home_account_id`, `client_id`, and `scope`; otherwise both
# `home_account_id` and `client_id` must be supplied directly.
find_msal_token <- function(
  cache_file = default_msal_token_cache(),
  home_account_id = NULL,
  client_id = NULL,
  access_token = NULL
) {
  cache <- read_msal_cache(cache_file)

  scope <- NULL
  if (!is.null(access_token)) {
    for (tok in cache$AccessToken %||% list()) {
      if (identical(tok$secret, access_token)) {
        home_account_id <- tok$home_account_id
        client_id <- tok$client_id
        scope <- tok$target
        break
      }
    }
  }

  if (is.null(home_account_id) || is.null(client_id)) {
    return(NULL)
  }

  refresh_token <- NULL
  for (rt in cache$RefreshToken %||% list()) {
    if (
      identical(rt$home_account_id, home_account_id) &&
        identical(rt$client_id, client_id)
    ) {
      refresh_token <- rt$secret
      break
    }
  }

  list(refresh_token = refresh_token, scope = scope)
}

#' Get Cached Token from MSAL Token Cache
#'
#' @description
#' Reads the MSAL token cache file (`msal_token_cache.json`) from the Azure
#' configuration directory and returns a matching access token as an
#' [httr2::oauth_token()] object.
#'
#' @details
#' The MSAL token cache is a JSON file maintained by the Azure CLI that stores
#' access tokens and refresh tokens. This function reads cached access tokens
#' directly from the file without invoking the Azure CLI, which can be useful
#' in environments where the CLI is slow or unavailable but tokens have been
#' previously cached.
#'
#' When multiple tokens are found, the function selects the token that expires
#' latest. If `scope` is provided, only tokens matching that scope/resource are
#' returned.
#'
#' @param scope A character string specifying the OAuth2 scope to filter tokens.
#'   If `NULL` (default), returns the latest-expiring token regardless of scope.
#' @param tenant_id A character string specifying the tenant ID to filter tokens.
#'   If `NULL` (default), matches any tenant.
#' @param client_id A character string specifying the client ID to filter tokens.
#'   If `NULL` (default), matches any client.
#' @param config_dir A character string specifying the Azure configuration
#'   directory. Defaults to [default_azure_config_dir()].
#'
#' @return An [httr2::oauth_token()] object containing:
#'   - `access_token`: The OAuth2 access token string
#'   - `token_type`: The type of token (typically "Bearer")
#'   - `.expires_at`: POSIXct timestamp when the token expires
#'
#' @export
az_cli_get_cached_token <- function(
  scope = NULL,
  tenant_id = NULL,
  client_id = NULL,
  config_dir = default_azure_config_dir()
) {
  cache_file <- file.path(config_dir, "msal_token_cache.json")

  if (!file.exists(cache_file)) {
    cli::cli_abort(
      c(
        "MSAL token cache file not found at {.path {cache_file}}",
        "i" = "Ensure you have logged in with {.code az login}"
      ),
      class = "azr_cli_cache_not_found"
    )
  }

  cache <- read_msal_cache(cache_file)

  tokens <- cache$AccessToken
  if (is.null(tokens) || length(tokens) == 0L) {
    cli::cli_abort(
      c(
        "No access tokens found in MSAL token cache",
        "i" = "Ensure you have logged in with {.code az login}"
      ),
      class = "azr_cli_cache_empty"
    )
  }

  # Filter by scope/resource
  if (!is.null(scope)) {
    resource <- get_scope_resource(scope)
    tokens <- Filter(
      function(tok) {
        target <- tok$target %||% ""
        # Match if scope appears in target or resource matches
        grepl(scope, target, fixed = TRUE) ||
          (!is.null(resource) && grepl(resource, target, fixed = TRUE))
      },
      tokens
    )
  }

  # Filter by tenant_id (realm field in MSAL cache)
  if (!is.null(tenant_id)) {
    tokens <- Filter(
      function(tok) {
        identical(tok$realm, tenant_id)
      },
      tokens
    )
  }

  # Filter by client_id
  if (!is.null(client_id)) {
    tokens <- Filter(
      function(tok) {
        identical(tok$client_id, client_id)
      },
      tokens
    )
  }

  if (length(tokens) == 0L) {
    cli::cli_abort(
      c(
        "No matching access token found in MSAL token cache",
        "i" = "Try logging in with {.code az login} to refresh your tokens"
      ),
      class = "azr_cli_cache_no_match"
    )
  }

  # Select the token with the latest expiry
  expires <- vapply(
    tokens,
    function(tok) {
      as.numeric(tok$expires_on %||% "0")
    },
    numeric(1)
  )

  best <- tokens[[which.max(expires)]]

  expires_at <- as.POSIXct(
    as.numeric(best$expires_on),
    origin = "1970-01-01",
    tz = "UTC"
  )

  token_info <- find_msal_token(
    cache_file,
    access_token = best$secret
  )

  httr2::oauth_token(
    access_token = best$secret,
    token_type = best$token_type %||% "Bearer",
    refresh_token = token_info[["refresh_token"]],
    .expires_at = expires_at
  )
}


launch_device_code <- function(code) {
  html_content <- system.file("www/code.html", package = "azr") |>
    readLines() |>
    paste(collapse = "\n") |>
    sprintf(code)

  temp_file <- tempfile(fileext = ".html")
  writeLines(html_content, temp_file)
  utils::browseURL(temp_file)
}
