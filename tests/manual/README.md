# Manual tests

Tests in this directory hit real Azure infrastructure to validate the
credential chain end-to-end. They are intentionally placed outside
`tests/testthat/` so that:

- `devtools::test()` does **not** discover them.
- `R CMD check` and CI/CD do **not** run them (the `tests/` tree is also
  ignored by `.Rbuildignore`).

Run them by hand when you have a working Azure environment.

## How to run

From the package root, with the package loaded:

```r
# Load the package under development
devtools::load_all()

# Run a single manual test file
testthat::test_file("tests/manual/test-default-credential.R")
```

To run every manual test file:

```r
devtools::load_all()
for (f in list.files("tests/manual", "^test-.*\\.R$", full.names = TRUE)) {
  testthat::test_file(f)
}
```

## Environment

Set the variables you want the chain to pick up before running, e.g.:

```sh
# Service principal
export AZURE_TENANT_ID=...
export AZURE_CLIENT_ID=...
export AZURE_CLIENT_SECRET=...

# Or rely on `az login` for the AzureCLICredential branch
az login
```
