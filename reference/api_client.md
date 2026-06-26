# Azure API Client

An R6 class that provides a base HTTP client for interacting with Azure
APIs. This client handles authentication, request building, retry logic,
logging, and error handling for Azure API requests.

## Details

The `api_client` class is designed to be a base class for Azure
service-specific clients. It provides:

- Automatic authentication using Azure credentials

- Configurable retry logic with exponential backoff

- Request and response logging

- JSON, XML, and HTML content type handling

- Standardized error handling

## Public fields

- `.host_url`:

  Base URL for the API

- `.base_req`:

  Base httr2 request object

- `.provider`:

  Credential provider R6 object

- `.credentials`:

  Credentials function for authentication

- `.options`:

  Request options (timeout, connecttimeout, max_tries)

- `.response_handler`:

  Optional callback function to process response content

- `.verbose`:

  Logical flag controlling request/response logging in `.send_request()`

## Methods

### Public methods

- [`api_client$new()`](#method-api_client-new)

- [`api_client$.fetch()`](#method-api_client-.fetch)

- [`api_client$.resp_content()`](#method-api_client-.resp_content)

- [`api_client$.build_request()`](#method-api_client-.build_request)

- [`api_client$.send_request()`](#method-api_client-.send_request)

- [`api_client$.resp_body_content()`](#method-api_client-.resp_body_content)

- [`api_client$.get_token()`](#method-api_client-.get_token)

- [`api_client$clone()`](#method-api_client-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new API client instance

#### Usage

    api_client$new(
      host_url,
      provider = NULL,
      credentials = NULL,
      timeout = 60L,
      connecttimeout = 30L,
      max_tries = 5L,
      response_handler = NULL,
      verbose = opts$get("api_verbose")
    )

#### Arguments

- `host_url`:

  A character string specifying the base URL for the API (e.g.,
  `"https://management.azure.com"`).

- `provider`:

  An R6 credential provider object that inherits from the `Credential`
  or `DefaultCredential` class. If provided, the credential's `req_auth`
  method will be used for authentication. Takes precedence over
  `credentials`.

- `credentials`:

  A function that adds authentication to requests. If both `provider`
  and `credentials` are `NULL`, uses
  [`default_non_auth()`](https://pedrobtz.github.io/azr/reference/default_non_auth.md).
  The function should accept an httr2 request object and return a
  modified request with authentication.

- `timeout`:

  An integer specifying the request timeout in seconds. Defaults to
  `60`.

- `connecttimeout`:

  An integer specifying the connection timeout in seconds. Defaults to
  `30`.

- `max_tries`:

  An integer specifying the maximum number of retry attempts for failed
  requests. Defaults to `5`.

- `response_handler`:

  An optional function to process the parsed response content. The
  function should accept one argument (the parsed response) and return
  the processed content. If `NULL`, uses
  [`default_response_handler()`](https://pedrobtz.github.io/azr/reference/default_response_handler.md)
  which converts data frames to data.table objects. Defaults to `NULL`.

- `verbose`:

  A logical flag controlling request/response logging in
  `.send_request()`. When `FALSE`, the `>>>` request and `<<<` response
  `cli` alerts are suppressed. Defaults to the `api_verbose` option,
  which reads `options(azr.api_verbose = ...)` or the `AZR_API_VERBOSE`
  environment variable; see
  [`azr_options()`](https://pedrobtz.github.io/azr/reference/azr_options.md).

#### Returns

A new `api_client` object

------------------------------------------------------------------------

### Method `.fetch()`

Make an HTTP request to the API

#### Usage

    api_client$.fetch(
      path,
      ...,
      query = NULL,
      body = NULL,
      headers = NULL,
      method = "get",
      verbosity = 0L,
      content = c("body", "headers", "response", "request"),
      content_type = NULL
    )

#### Arguments

- `path`:

  A character string specifying the API endpoint path. Supports
  [`rlang::englue()`](https://rlang.r-lib.org/reference/englue.html)
  syntax for variable interpolation using named arguments passed via
  `...`.

- `...`:

  Named arguments used for path interpolation with
  [`rlang::englue()`](https://rlang.r-lib.org/reference/englue.html).

- `query`:

  A named list of query parameters to append to the URL.

- `body`:

  Request body data. Sent as JSON in the request body. Can be a list or
  character string (JSON).

- `headers`:

  A named list of additional HTTP headers to include in the request.

- `method`:

  A character string specifying the HTTP method. One of `"get"`,
  `"post"`, `"put"`, `"patch"`, or `"delete"`. Defaults to `"get"`.

- `verbosity`:

  An integer specifying the verbosity level for request debugging
  (passed to
  [`httr2::req_perform()`](https://httr2.r-lib.org/reference/req_perform.html)).
  Defaults to `0`.

- `content`:

  A character string specifying what to return. One of:

  - `"body"` (default): Return the parsed response body

  - `"headers"`: Return response headers

  - `"response"`: Return the full httr2 response object

  - `"request"`: Return the prepared request object without executing it

- `content_type`:

  A character string specifying how to parse the response body. If
  `NULL`, uses the response's Content-Type header. Common values:
  `"application/json"`, `"application/xml"`, `"text/html"`.

#### Returns

Depends on the `content` parameter:

- `"body"`: Parsed response body (list, data.frame, or character)

- `"headers"`: List of response headers

- `"response"`: Full
  [`httr2::response()`](https://httr2.r-lib.org/reference/response.html)
  object

- `"request"`:
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object

------------------------------------------------------------------------

### Method `.resp_content()`

Extract content from a response object

#### Usage

    api_client$.resp_content(resp, content, content_type = NULL)

#### Arguments

- `resp`:

  An
  [`httr2::response()`](https://httr2.r-lib.org/reference/response.html)
  object

- `content`:

  A character string specifying what to return. One of:

  - `"body"`: Return the parsed response body

  - `"headers"`: Return response headers

  - `"response"`: Return the full httr2 response object

- `content_type`:

  A character string specifying how to parse the response body. Only
  used when `content = "body"`. If `NULL`, uses the response's
  Content-Type header.

#### Returns

Depends on the `content` parameter:

- `"body"`: Parsed response body (list, data.frame, or character)

- `"headers"`: List of response headers

- `"response"`: Full
  [`httr2::response()`](https://httr2.r-lib.org/reference/response.html)
  object

------------------------------------------------------------------------

### Method `.build_request()`

Build an HTTP request object

#### Usage

    api_client$.build_request(
      path,
      ...,
      query = NULL,
      body = NULL,
      headers = NULL,
      method = "get"
    )

#### Arguments

- `path`:

  A character string specifying the API endpoint path. Supports
  [`rlang::englue()`](https://rlang.r-lib.org/reference/englue.html)
  syntax for variable interpolation using named arguments passed via
  `...`.

- `...`:

  Named arguments used for path interpolation with
  [`rlang::englue()`](https://rlang.r-lib.org/reference/englue.html).

- `query`:

  A named list of query parameters to append to the URL.

- `body`:

  Request body data. Sent as JSON in the request body. Can be a list or
  character string (JSON).

- `headers`:

  A named list of additional HTTP headers to include in the request.

- `method`:

  A character string specifying the HTTP method. One of `"get"`,
  `"post"`, `"put"`, `"patch"`, or `"delete"`. Defaults to `"get"`.

#### Returns

An [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
object ready for execution

------------------------------------------------------------------------

### Method `.send_request()`

Perform an HTTP request and log the results

#### Usage

    api_client$.send_request(req, verbosity)

#### Arguments

- `req`:

  An
  [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
  object to execute

- `verbosity`:

  An integer specifying the verbosity level for request debugging
  (passed to
  [`httr2::req_perform()`](https://httr2.r-lib.org/reference/req_perform.html)).
  Defaults to `0`.

#### Returns

An
[`httr2::response()`](https://httr2.r-lib.org/reference/response.html)
object containing the API response

------------------------------------------------------------------------

### Method `.resp_body_content()`

Extract and parse response content

#### Usage

    api_client$.resp_body_content(resp, content_type = NULL)

#### Arguments

- `resp`:

  An
  [`httr2::response()`](https://httr2.r-lib.org/reference/response.html)
  object

- `content_type`:

  A character string specifying how to parse the response body. If
  `NULL`, uses the response's Content-Type header. Common values:
  `"application/json"`, `"application/xml"`, `"text/html"`.

#### Returns

Parsed response body. Format depends on content type:

- JSON: List or data.frame

- XML: xml2 document

- HTML: xml2 document

- Other: Character string

------------------------------------------------------------------------

### Method `.get_token()`

Get authentication token from the credential provider

#### Usage

    api_client$.get_token()

#### Returns

An
[`httr2::oauth_token()`](https://httr2.r-lib.org/reference/oauth_token.html)
object if a provider is available, otherwise returns `NULL` with a
warning.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    api_client$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a client with default credentials
client <- api_client$new(
  host_url = "https://management.azure.com"
)

# Create a client with a credential provider
cred_provider <- get_credential_provider(
  scope = "https://management.azure.com/.default"
)
client <- api_client$new(
  host_url = "https://management.azure.com",
  provider = cred_provider
)

# Create a client with custom credentials function
client <- api_client$new(
  host_url = "https://management.azure.com",
  credentials = my_credential_function,
  timeout = 120,
  max_tries = 3
)

# Create a client with custom response handler
custom_handler <- function(content) {
  # Custom processing logic - e.g., keep data frames as-is
  content
}
client <- api_client$new(
  host_url = "https://management.azure.com",
  response_handler = custom_handler
)

# Make a GET request
response <- client$.fetch(
  path = "/subscriptions/{subscription_id}/resourceGroups",
  subscription_id = "my-subscription-id",
  query = list(`api-version` = "2021-04-01"),
  method = "get"
)
} # }
```
