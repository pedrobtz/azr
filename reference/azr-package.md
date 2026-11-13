# azr: Credential Chain for OAuth 2.0 Authentication to 'Azure'

Implements a credential chain for 'Azure' OAuth 2.0 authentication,
built on the OAuth framework of the 'httr2' package. Tries
authentication methods in turn until one succeeds, so the same code runs
on a laptop, in continuous integration and on an 'Azure' host. Supports
client secret, workload identity, managed identity and 'Azure CLI'
credentials, plus interactive device code and authorization code flows
during development.

## See also

Useful links:

- <https://pedrobtz.github.io/azr/>

- <https://github.com/pedrobtz/azr>

- Report bugs at <https://github.com/pedrobtz/azr/issues>

## Author

**Maintainer**: Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]

Authors:

- Pedro Baltazar <pedrobtz@gmail.com> \[copyright holder\]
