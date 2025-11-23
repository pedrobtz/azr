# Microsoft Graph API Resource

An R6 class that extends
[api_resource](https://pedrobtz.github.io/azr/reference/api_resource.md)
to provide specialized methods for the Microsoft Graph API. This class
adds convenience methods for common Graph operations.

## Super class

[`azr::api_resource`](https://pedrobtz.github.io/azr/reference/api_resource.md)
-\> `api_graph_resource`

## Methods

### Public methods

- [`api_graph_resource$me()`](#method-api_graph_resource-me)

- [`api_graph_resource$clone()`](#method-api_graph_resource-clone)

Inherited methods

- [`azr::api_resource$initialize()`](https://pedrobtz.github.io/azr/reference/api_resource.html#method-initialize)

------------------------------------------------------------------------

### Method `me()`

Fetch the current user's profile

#### Usage

    api_graph_resource$me(select = NULL)

#### Arguments

- `select`:

  A character vector of properties to select (e.g., c("displayName",
  "mail")). If NULL, all properties are returned.

#### Returns

The response from the /me endpoint

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    api_graph_resource$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
