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
    #' @param login A logical value indicating whether to check if the user is
    #'   logged in and perform login if needed. Defaults to `FALSE`.
    #' @param use_bridge A logical value indicating whether to use the device code
    #'   bridge webpage during login. If `TRUE`, launches an intermediate local webpage
    #'   that displays the device code and facilitates copy-pasting before redirecting
    #'   to the Microsoft device login page. Only used when `login = TRUE`. Defaults to `FALSE`.
    #'
    #' @return A new `AzureCLICredential` object
    initialize = function(
      scope = NULL,
      tenant_id = NULL,
      process_timeout = NULL,
      login = FALSE,
      use_bridge = FALSE
    ) {
      super$initialize(scope = scope, tenant_id = tenant_id)
      self$.process_timeout <- process_timeout %||% self$.process_timeout

      if (isTRUE(login)) {
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
#' @examples
#' \dontrun{
#' # Get a token for Azure Resource Manager
#' token <- az_cli_get_token(
#'   scope = "https://management.azure.com/.default"
#' )
#'
#' # Get a token for a specific tenant
#' token <- az_cli_get_token(
#'   scope = "https://graph.microsoft.com/.default",
#'   tenant_id = "your-tenant-id"
#' )
#'
#' # Access the token string
#' access_token <- token$access_token
#' }
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

  httr2::oauth_token(
    access_token = token$accessToken,
    token_type = token$tokenType,
    .expires_at = expires_at
  )
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
#' @examples
#' \dontrun{
#' # Check if logged in
#' if (az_cli_is_login()) {
#'   message("User is logged in")
#' } else {
#'   message("User is not logged in")
#' }
#' }
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
#' @examples
#' \dontrun{
#' # Perform Azure CLI login with device code flow
#' az_cli_login()
#'
#' # Use the bridge webpage for easier code handling
#' az_cli_login(use_bridge = TRUE)
#'
#' # Login to a specific tenant with verbose output
#' az_cli_login(tenant_id = "your-tenant-id", verbose = TRUE)
#' }
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
#' @examples
#' \dontrun{
#' # Get current account information
#' account_info <- az_cli_account_show()
#'
#' # Access subscription ID
#' subscription_id <- account_info$id
#'
#' # Access tenant ID
#' tenant_id <- account_info$tenantId
#' }
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
#' @examples
#' \dontrun{
#' # Log out from Azure CLI
#' az_cli_logout()
#' }
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

launch_device_code <- function(code) {
  html_content <- system.file("code.html", package = "azr") |>
    readLines() |>
    paste(collapse = "\n") |>
    sprintf(code)

  temp_file <- tempfile(fileext = ".html")
  writeLines(html_content, temp_file)
  utils::browseURL(temp_file)
}
