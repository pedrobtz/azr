# Changelog

## azr (development version)

## azr 0.2.1

CRAN release: 2026-01-07

### New features

- Added `DefaultCredential` for simplified authentication using Azure’s
  default credential chain.

### Bug fixes and improvements

- Removed dependency on httpuv package.

## azr 0.2.0

CRAN release: 2025-12-04

### New features

- Added `api_client` R6 class providing a base HTTP client for Azure
  APIs with automatic authentication, retry logic, and error handling.
- Added `api_resource` and `api_services` classes for Azure Resource
  Manager interactions.
- Introduced custom credentials function support in API clients for
  flexible authentication.
- Added response handler callbacks to customize API response processing.

### Authentication improvements

- Enhanced credential chain with support for Azure CLI authentication.
- Added interactive authentication flows (Device Code and Auth Code).
- Improved client secret credential handling.
- Fixed authentication issues with auth-code flow.

### Bug fixes and improvements

- Fixed credential validation to properly check function objects in
  `api_client`.
- Fixed issues with Graph client authentication and request handling.
- Improved error messages and logging throughout the package.
- Added comprehensive tests for core functionality.
- Enhanced documentation with examples and usage guides.

## azr 0.1.0

CRAN release: 2025-11-04

- Initial CRAN submission.
