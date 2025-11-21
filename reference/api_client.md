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

- `.credentials`:

  Credentials function for authentication

- `.options`:

  Request options (timeout, connecttimeout, max_tries)

## Methods

### Public methods

- [`api_client$new()`](#method-api_client-new)

- [`api_client$.fetch()`](#method-api_client-.fetch)

- [`api_client$.req_build()`](#method-api_client-.req_build)

- [`api_client$.req_perform()`](#method-api_client-.req_perform)

- [`api_client$.resp_content()`](#method-api_client-.resp_content)

------------------------------------------------------------------------

### Method `new()`

Create a new API client instance

#### Usage

    api_client$new(
      host_url,
      credentials = NULL,
      timeout = 60L,
      connecttimeout = 30L,
      max_tries = 5L
    )

#### Arguments

- `host_url`:

  A character string specifying the base URL for the API (e.g.,
  `"https://management.azure.com"`).

- `credentials`:

  A function that adds authentication to requests. If `NULL`, uses
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

#### Returns

A new `api_client` object

------------------------------------------------------------------------

### Method `.fetch()`

Make an HTTP request to the API

#### Usage

    api_client$.fetch(
      path,
      ...,
      req_data = NULL,
      req_method = "get",
      verbosity = 0L,
      content = c("body", "headers", "response", "request"),
      content_type = NULL
    )

#### Arguments

- `path`:

  A character string specifying the API endpoint path. Supports
  [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html)
  syntax for variable interpolation using named arguments passed via
  `...`.

- `...`:

  Named arguments used for path interpolation with
  [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html).

- `req_data`:

  Request data. For GET requests, this is used as query parameters. For
  other methods, this is sent as JSON in the request body. Can be a list
  or character string (JSON).

- `req_method`:

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

### Method `.req_build()`

Build an HTTP request object

#### Usage

    api_client$.req_build(path, ..., req_data = NULL, req_method = "get")

#### Arguments

- `path`:

  A character string specifying the API endpoint path. Supports
  [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html)
  syntax for variable interpolation using named arguments passed via
  `...`.

- `...`:

  Named arguments used for path interpolation with
  [`glue::glue()`](https://glue.tidyverse.org/reference/glue.html).

- `req_data`:

  Request data. For GET requests, this is used as query parameters. For
  other methods, this is sent as JSON in the request body. Can be a list
  or character string (JSON).

- `req_method`:

  A character string specifying the HTTP method. One of `"get"`,
  `"post"`, `"put"`, `"patch"`, or `"delete"`. Defaults to `"get"`.

#### Returns

An [`httr2::request()`](https://httr2.r-lib.org/reference/request.html)
object ready for execution

------------------------------------------------------------------------

### Method `.req_perform()`

Perform an HTTP request and log the results

#### Usage

    api_client$.req_perform(req, verbosity)

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

### Method `.resp_content()`

Extract and parse response content

#### Usage

    api_client$.resp_content(resp, content_type = NULL)

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

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a client with default credentials
client <- api_client$new(
  host_url = "https://management.azure.com"
)

# Create a client with custom credentials and options
client <- api_client$new(
  host_url = "https://management.azure.com",
  credentials = my_credential_function,
  timeout = 120,
  max_tries = 3
)

# Make a GET request
response <- client$.request(
  path = "/subscriptions/{subscription_id}/resourceGroups",
  subscription_id = "my-subscription-id",
  req_method = "get"
)
} # }
```
