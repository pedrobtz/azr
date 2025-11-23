# Microsoft Graph API Client

An R6 class that extends
[api_client](https://pedrobtz.github.io/azr/reference/api_client.md)
with Microsoft Graph-specific defaults. This client is preconfigured
with the Graph API host URL and scope.

## Super class

[`azr::api_client`](https://pedrobtz.github.io/azr/reference/api_client.md)
-\> `api_graph_client`

## Methods

### Public methods

- [`api_graph_client$new()`](#method-api_graph_client-new)

- [`api_graph_client$clone()`](#method-api_graph_client-clone)

Inherited methods

- [`azr::api_client$.fetch()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.fetch)
- [`azr::api_client$.get_token()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.get_token)
- [`azr::api_client$.req_build()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.req_build)
- [`azr::api_client$.req_perform()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.req_perform)
- [`azr::api_client$.resp_content()`](https://pedrobtz.github.io/azr/reference/api_client.html#method-.resp_content)

------------------------------------------------------------------------

### Method `new()`

Create a new Microsoft Graph API client instance

#### Usage

    api_graph_client$new(
      provider = NULL,
      host_url = "https://graph.microsoft.com",
      ...
    )

#### Arguments

- `provider`:

  A credential provider for authentication. If NULL, will be passed to
  [api_client](https://pedrobtz.github.io/azr/reference/api_client.md).

- `host_url`:

  The Microsoft Graph API base URL. Defaults to
  "https://graph.microsoft.com".

- `...`:

  Additional arguments passed to
  [api_client](https://pedrobtz.github.io/azr/reference/api_client.md)
  constructor.

#### Returns

A new `api_graph_client` object

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    api_graph_client$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
