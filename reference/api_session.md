# Azure API Session

An R6 class that provides a session wrapper for Azure API interactions.
This class manages an API client instance and provides a higher-level
interface for working with Azure APIs.

## Details

The `api_session` class wraps an `api_client` instance to provide
session management for Azure API interactions. It simplifies the process
of maintaining a persistent connection to an Azure API endpoint with
consistent authentication and configuration.

## Public fields

- `.client`:

  An instance of the api_client class

## Methods

### Public methods

- [`api_session$new()`](#method-api_session-new)

- [`api_session$clone()`](#method-api_session-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new API session instance

#### Usage

    api_session$new(
      host_url,
      credentials = NULL,
      timeout = 60L,
      connecttimeout = 30L,
      max_tries = 5L,
      ...
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

- `...`:

  Additional arguments (currently unused).

#### Returns

A new `api_session` object

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    api_session$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a session with default credentials
session <- api_session$new(
  host_url = "https://management.azure.com"
)

# Create a session with custom credentials and options
session <- api_session$new(
  host_url = "https://management.azure.com",
  credentials = my_credential_function,
  timeout = 120,
  max_tries = 3
)
} # }
```
