# Microsoft Graph API Service

An R6 class that extends
[api_service](https://pedrobtz.github.io/azr/reference/api_service.md)
with Microsoft Graph-specific configuration. This service is
preconfigured with Graph API client and endpoints (v1.0 and beta).

## Super class

[`azr::api_service`](https://pedrobtz.github.io/azr/reference/api_service.md)
-\> `api_graph_service`

## Methods

### Public methods

- [`api_graph_service$new()`](#method-api_graph_service-new)

- [`api_graph_service$clone()`](#method-api_graph_service-clone)

------------------------------------------------------------------------

### Method `new()`

Create a new Microsoft Graph API service instance

#### Usage

    api_graph_service$new(chain = NULL, ...)

#### Arguments

- `chain`:

  A
  [credential_chain](https://pedrobtz.github.io/azr/reference/credential_chain.md)
  instance for authentication. If NULL, a default credential chain will
  be created.

- `...`:

  Additional arguments passed to
  [api_graph_client](https://pedrobtz.github.io/azr/reference/api_graph_client.md)
  constructor.

#### Returns

A new `api_graph_service` object

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    api_graph_service$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
