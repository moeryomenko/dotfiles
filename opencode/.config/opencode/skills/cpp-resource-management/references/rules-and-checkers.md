# Resource Management (R Section) - Rules and Checker Mapping

## R.1 - R.15: RAII and Allocation

| Rule | Guideline | Checker |
|------|-----------|---------|
| R.1 | RAII for automatic resource management | `bugprone-unused-raii`, `bugprone-unused-local-non-trivial-variable`, `bugprone-dangling-handle` |
| R.2 | Raw pointers in interfaces for non-owning | -- |
| R.3 | Raw pointer (`T*`) is non-owning | `cppcoreguidelines-owning-memory` |
| R.4 | Raw reference (`T&`) is non-owning | `cppcoreguidelines-owning-memory` |
| R.5 | Prefer scoped objects, don't heap-allocate unnecessarily | -- |
| R.6 | Avoid non-`const` global variables | `cppcoreguidelines-avoid-non-const-global-variables` |
| R.10 | Avoid `malloc()`/`free()` | `cppcoreguidelines-no-malloc` |
| R.11 | Avoid explicit `new`/`delete` | `cppcoreguidelines-owning-memory` |
| R.12 | Give allocation result to manager immediately | -- |
| R.13 | At most one explicit allocation per statement | `bugprone-multiple-new-in-one-expression` |
| R.14 | Avoid `[]` params, prefer `span` | `cppcoreguidelines-pro-bounds-array-to-pointer-decay` |
| R.15 | Overload matched alloc/dealloc pairs | `misc-new-delete-overloads`, `cert-dcl58-cpp` |

## R.20 - R.37: Smart Pointers

| Rule | Guideline | Checker |
|------|-----------|---------|
| R.20 | `unique_ptr`/`shared_ptr` for ownership | `cppcoreguidelines-owning-memory`, `modernize-replace-auto-ptr`, `bugprone-shared-ptr-array-mismatch`, `bugprone-unique-ptr-array-mismatch` |
| R.21 | Prefer `unique_ptr` over `shared_ptr` | -- |
| R.22 | `make_shared()` for `shared_ptr` | `modernize-make-shared` |
| R.23 | `make_unique()` for `unique_ptr` | `modernize-make-unique` |
| R.24 | `weak_ptr` to break `shared_ptr` cycles | -- |
| R.30 | Smart ptr params only for lifetime semantics | -- |
| R.31 | Non-std smart ptrs follow std pattern | -- |
| R.32 | `unique_ptr<W>` param = takes ownership | -- |
| R.33 | `unique_ptr<W>&` param = may reseat | -- |
| R.34 | `shared_ptr<W>` param = shares ownership | -- |
| R.35 | `shared_ptr<W>&` param = may reseat | -- |
| R.36 | `const shared_ptr<W>&` = may retain ref | -- |
| R.37 | No pointer/ref from aliased smart ptr | -- |

## Additional Related Checkers

| Checker | Purpose |
|---------|---------|
| `bugprone-misplaced-operator-in-strlen-in-alloc` | Incorrect size calculation |
| `bugprone-misplaced-pointer-arithmetic-in-alloc` | Incorrect pointer arithmetic in alloc |
| `bugprone-incorrect-enable-shared-from-this` | Misuse of `enable_shared_from_this` |
| `readability-redundant-smartptr-get` | Unnecessary `.get()` on smart pointer |
| `misc-uniqueptr-reset-release` | Potential leak from `.reset()`/`.release()` |
