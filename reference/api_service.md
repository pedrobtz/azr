# API Service Base Class

Base R6 class for creating API service wrappers. This class provides a
foundation for building service-specific API clients with
authentication, endpoint management, and configuration.

## Public fields

- `.client`:

  An
  [api_client](https://pedrobtz.github.io/azr/reference/api_client.md)
  instance for making API requests

## Methods

### Public methods

- [`api_service$new()`](#method-api_service-new)

------------------------------------------------------------------------

### Method `new()`

Create a new API service instance

#### Usage

    api_service$new(
      client = NULL,
      chain = NULL,
      endpoints = list(),
      config = list()
    )

#### Arguments

- `client`:

  An
  [api_client](https://pedrobtz.github.io/azr/reference/api_client.md)
  instance. If `NULL`, a new client will be created.

- `chain`:

  A
  [credential_chain](https://pedrobtz.github.io/azr/reference/credential_chain.md)
  instance for authentication. Optional.

- `endpoints`:

  A named list where names are endpoint paths (e.g., "v1.0", "beta") and
  values are R6 class objects (not instances) to use for creating
  resources. Defaults to an empty list. If the value is `NULL`,
  [api_resource](https://pedrobtz.github.io/azr/reference/api_resource.md)
  will be used.

- `config`:

  A list of configuration options. Defaults to an empty list.

#### Returns

A new `api_service` object
