# Interactive credential base class

Base class for interactive authentication credentials. This class should
not be instantiated directly; use
[DeviceCodeCredential](https://pedrobtz.github.io/azr/reference/DeviceCodeCredential.md)
or
[AuthCodeCredential](https://pedrobtz.github.io/azr/reference/AuthCodeCredential.md)
instead.

## Super class

`azr::Credential` -\> `InteractiveCredential`

## Methods

### Public methods

- [`InteractiveCredential$is_interactive()`](#method-InteractiveCredential-is_interactive)

- [`InteractiveCredential$clone()`](#method-InteractiveCredential-clone)

Inherited methods

- [`azr::Credential$initialize()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-initialize)
- [`azr::Credential$print()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-print)
- [`azr::Credential$validate()`](https://pedrobtz.github.io/azr/reference/Credential.html#method-validate)

------------------------------------------------------------------------

### Method `is_interactive()`

Check if the credential is interactive

#### Usage

    InteractiveCredential$is_interactive()

#### Returns

Always returns `TRUE` for interactive credentials

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    InteractiveCredential$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
