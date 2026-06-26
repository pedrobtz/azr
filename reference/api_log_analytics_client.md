# Azure Log Analytics API Class

An R6 class that extends
[api_client](https://pedrobtz.github.io/azr/reference/api_client.md) to
provide a Kusto Query Language (KQL) `query()` method against the public
Azure Log Analytics REST API, bound to a specific Azure subscription and
resource group at construction.

## Details

The client is bound to `subscription_id` and `resource_id` (the resource
group name) at construction. The `$query()` method issues a `POST` to
`https://{endpoint}/{api_version}/subscriptions/{subscription_id}/resourceGroups/{resource_id}/query`
with a JSON body
(`{"query": ..., "timespan": ..., "workspaces": [...]}`).

Pass `scope = "hierarchy"` (or any other supported query-string
parameter) via `...` on `$query()` to traverse the resource hierarchy.

## Super class

[`azr::api_client`](https://pedrobtz.github.io/azr/reference/api_client.md)
-\> `api_log_analytics_client`

## Public fields

- `.subscription_id`:

  The Azure subscription ID the client is bound to.

- `.resource_id`:

  The Azure resource group name the client is bound to.

- `.api_version`:

  The API version segment prepended to all query paths.

## Methods

### Public methods

- [`api_log_analytics_client$new()`](#method-api_log_analytics_client-new)

- [`api_log_analytics_client$query()`](#method-api_log_analytics_client-query)

- [`api_log_analytics_client$clone()`](#method-api_log_analytics_client-clone)

Inherited methods

- [`azr::api_client$.build_request()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.build_request)
- [`azr::api_client$.fetch()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.fetch)
- [`azr::api_client$.get_token()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.get_token)
- [`azr::api_client$.resp_body_content()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.resp_body_content)
- [`azr::api_client$.resp_content()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.resp_content)
- [`azr::api_client$.send_request()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.send_request)

------------------------------------------------------------------------

### Method `new()`

Create a new Azure Log Analytics API client instance bound to a specific
subscription and resource group.

#### Usage

    api_log_analytics_client$new(
      subscription_id,
      resource_id,
      endpoint = default_log_analytics_endpoint(),
      api_version = "v1",
      scope = default_azure_scope("azure_log_analytics"),
      provider = NULL,
      chain = NULL,
      tenant_id = NULL,
      ...
    )

#### Arguments

- `subscription_id`:

  A character string specifying the Azure subscription ID (GUID) to bind
  the client to.

- `resource_id`:

  A character string specifying the Azure resource group name to bind
  the client to.

- `endpoint`:

  A character string specifying the Log Analytics query endpoint host
  (e.g. `"api.loganalytics.io"`). Defaults to
  [`default_log_analytics_endpoint()`](https://pedrobtz.github.io/azr/reference/default_log_analytics_endpoint.md).
  Any leading `https?://` scheme or trailing slashes are stripped.

- `api_version`:

  A character string specifying the API version segment prepended to the
  query path. Defaults to `"v1"`.

- `scope`:

  A character string specifying the OAuth2 scope. Defaults to
  `default_azure_scope("azure_log_analytics")`.

- `provider`:

  An optional credential provider object that inherits from `Credential`
  or `DefaultCredential`. If provided, `chain` is ignored.

- `chain`:

  A
  [credential_chain](https://pedrobtz.github.io/azr/reference/credential_chain.md)
  instance for authentication. If `NULL`, a default credential chain is
  created using
  [DefaultCredential](https://pedrobtz.github.io/azr/reference/DefaultCredential.md).

- `tenant_id`:

  A character string specifying the Azure tenant ID. Passed to
  [DefaultCredential](https://pedrobtz.github.io/azr/reference/DefaultCredential.md)
  when `chain` is `NULL`.

- `...`:

  Additional arguments passed to the parent
  [api_client](https://pedrobtz.github.io/azr/reference/api_client.md)
  constructor.

#### Returns

A new `api_log_analytics_client` object

------------------------------------------------------------------------

### Method `query()`

Issue a KQL query against the bound subscription and resource group.

#### Usage

    api_log_analytics_client$query(
      query,
      date_from = Sys.Date() - 3,
      date_to = Sys.Date() + 1,
      timespan = NULL,
      max_rows = 500001L,
      options = list(truncationMaxSize = 67108864L),
      workspace_filters = list(regions = list()),
      ...,
      raw = FALSE,
      coerce_types = TRUE
    )

#### Arguments

- `query`:

  A character string containing the KQL query to execute.

- `date_from`:

  Start of the time range as a `Date` or `POSIXct`. When provided
  together with `date_to`, appends
  `| where TimeGenerated between(datetime(...), datetime(...))` to the
  query and sets `timespan` to `NULL`. Defaults to `Sys.Date() - 3`.

- `date_to`:

  End of the time range as a `Date` or `POSIXct`. Defaults to
  `Sys.Date() + 1`.

- `timespan`:

  An ISO 8601 duration (e.g. `"PT12H"`) or start/end pair separated by
  `/` (e.g. `"2024-01-01/2024-01-02"`). Passed as a URL query parameter.
  Ignored when `date_from` and `date_to` are set. Defaults to `NULL`.

- `max_rows`:

  Maximum number of rows to return. Defaults to `500001`.

- `options`:

  A named list of query options. Defaults to
  `list(truncationMaxSize = 67108864)`.

- `workspace_filters`:

  A named list of workspace filters. Defaults to
  `list(regions = list())`.

- `...`:

  Additional URL query parameters. Override defaults (e.g.
  `scope = "resource"` to change from the default `"hierarchy"`).

- `raw`:

  If `TRUE`, returns the parsed JSON response as a list. If `FALSE` (the
  default), returns a named list of `data.frame`s — one per table in the
  response — or the single table directly if only one is returned.

- `coerce_types`:

  If `TRUE` (the default), columns are coerced to their native R types
  based on the Log Analytics schema (e.g. `datetime` → `POSIXct`, `bool`
  → `logical`). Set to `FALSE` to keep all values as character.

#### Returns

Either a single `data.frame`, a named list of `data.frame`s, or the raw
parsed response (when `raw = TRUE`).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    api_log_analytics_client$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
if (FALSE) { # \dontrun{
la <- api_log_analytics_client$new(
  subscription_id = "00000000-0000-0000-0000-000000000000",
  resource_id = "my-resource-group"
)

la$query(
  query = "AzureDiagnostics | take 10",
  timespan = "PT12H",
  scope = "hierarchy"
)
} # }
```
