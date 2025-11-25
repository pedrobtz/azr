# Azure API Resource

An R6 class that wraps an `api_client` and adds an additional path
segment (like "beta" or "v1.0") to all requests. This is useful for APIs
that version their endpoints or have different API surfaces under
different paths.

## Details

The `api_resource` class creates a modified base request by appending an
endpoint path to the client's base request. All subsequent API calls
through this resource will automatically include this path prefix.

## Public fields

- `.endpoint`:

  The API endpoint path segment (e.g., "v1.0", "beta")

- `.client`:

  The cloned api_client instance with modified base_req

## Active bindings

- `.endpoint`:

  The API endpoint path segment (e.g., "v1.0", "beta")

## Methods

### Public methods

- [`api_resource$new()`](#method-api_resource-new)

------------------------------------------------------------------------

### Method `new()`

Create a new API resource instance

#### Usage

    api_resource$new(client, endpoint)

#### Arguments

- `client`:

  An `api_client` object that provides the base HTTP client
  functionality. This will be cloned to avoid modifying the original.

- `endpoint`:

  A character string specifying the API endpoint or path segment to
  append (e.g., `"v1.0"`, `"beta"`).

#### Returns

A new `api_resource` object

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a client
client <- api_client$new(
  host_url = "https://graph.microsoft.com"
)

# Create a resource with v1.0 API endpoint
resource_v1 <- api_resource$new(
  client = client,
  endpoint = "v1.0"
)

# Create a resource with beta API endpoint
resource_beta <- api_resource$new(
  client = client,
  endpoint = "beta"
)

# Make requests - the endpoint is automatically prepended
response <- resource_v1$.fetch(
  path = "/me",
  req_method = "get"
)
} # }
```
