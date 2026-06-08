# Interfaces (I Section) - Rules and Checker Mapping

| Rule | Guideline | Checker |
|------|-----------|---------|
| I.1 | Make interfaces explicit | -- |
| I.2 | Avoid non-`const` global variables | `cppcoreguidelines-avoid-non-const-global-variables` |
| I.3 | Avoid singletons | -- |
| I.4 | Interfaces precisely and strongly typed | -- |
| I.5 | State preconditions | -- |
| I.6 | Prefer `Expects()` for preconditions | -- |
| I.7 | State postconditions | -- |
| I.8 | Prefer `Ensures()` for postconditions | -- |
| I.9 | Document template params with concepts | -- |
| I.10 | Exceptions for failed required tasks | -- |
| I.11 | No ownership transfer by raw pointer/reference | -- |
| I.12 | `not_null` for non-null pointers | -- |
| I.13 | No array as single pointer | `cppcoreguidelines-pro-bounds-array-to-pointer-decay` |
| I.22 | Avoid complex global object initialization | `cppcoreguidelines-interfaces-global-init`, `bugprone-throwing-static-initialization`, `misc-static-initialization-cycle` |
| I.23 | Keep function argument count low | -- |
| I.24 | Avoid adjacent swappable params | `bugprone-easily-swappable-parameters` |
| I.25 | Empty abstract classes as interfaces | -- |
| I.26 | C-style subset for cross-compiler ABI | -- |
| I.27 | Pimpl for stable library ABI | -- |
| I.30 | Encapsulate rule violations | -- |
