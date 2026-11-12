# Create Default Credential Chain

Creates the default chain of credentials to attempt during
authentication. The credentials are tried in order until one
successfully authenticates. The default chain includes:

1.  Client Secret Credential - Uses client ID and secret

2.  Workload Identity Credential - Federated token, e.g. an AKS pod

3.  Managed Identity Credential - The host's managed identity

4.  Azure CLI Credential - Uses credentials from Azure CLI

5.  Authorization Code Credential - Interactive browser-based
    authentication

6.  Device Code Credential - Interactive device code flow

## Usage

``` r
default_credential_chain()
```

## Value

A `credential_chain` object containing the default sequence of
credential providers.

## Narrowing the chain with `AZURE_TOKEN_CREDENTIALS`

Like `DefaultAzureCredential` in the Azure SDKs, the chain honours the
`AZURE_TOKEN_CREDENTIALS` environment variable, read each time the chain
is built. Matching is case-insensitive:

|  |  |
|----|----|
| Value | Entries kept |
| `"dev"` | `azure_cli`, `auth_code`, `device_code` |
| `"prod"` | `client_secret`, `workload_identity`, `managed_identity` |
| `"EnvironmentCredential"` or `"ClientSecretCredential"` | `client_secret` |
| `"WorkloadIdentityCredential"` | `workload_identity` |
| `"ManagedIdentityCredential"` | `managed_identity` |
| `"AzureCliCredential"` | `azure_cli` |
| `"InteractiveBrowserCredential"` or `"AuthCodeCredential"` | `auth_code` |
| `"DeviceCodeCredential"` | `device_code` |

Setting `"dev"` is how to keep a person's Azure CLI login from losing to
a workload or managed identity the host also offers. Unset or empty
keeps the whole chain. Any other value is an error, including the Azure
SDK names for credentials azr does not implement
(`AzureDeveloperCliCredential`, `AzurePowerShellCredential`,
`VisualStudioCodeCredential`). Chains built with
[`credential_chain()`](https://pedrobtz.github.io/azr/dev/reference/credential_chain.md)
are never filtered.

## See also

[`credential_chain()`](https://pedrobtz.github.io/azr/dev/reference/credential_chain.md),
[`get_token_provider()`](https://pedrobtz.github.io/azr/dev/reference/get_token_provider.md)
