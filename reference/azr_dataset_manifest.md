# Azure Storage dataset manifest

An S7 class representing the resolved information required by an
external reader to load an Azure Storage dataset. Use
[as.list()](https://rdrr.io/r/base/list.html) to convert it to a plain R
list.

## Usage

``` r
azr_dataset_manifest(
  name = character(0),
  uri = character(0),
  format = character(0)
)
```

## Arguments

- name:

  Dataset name, carried over from the source
  [azr_dataset](https://pedrobtz.github.io/azr/reference/azr_dataset.md).

- uri:

  Resolved Azure Storage URI.

- format:

  Dataset format. See
  [azr_dataset](https://pedrobtz.github.io/azr/reference/azr_dataset.md)
  for supported values.

## Value

An `azr_dataset_manifest` S7 object.
