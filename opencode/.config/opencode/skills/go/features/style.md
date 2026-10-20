# Go Style Guide

## Priorities

Apply the repository's established conventions first, provided they do not conflict with Go tooling, correctness, or a deliberate public-API change. Prefer code that is clear to its future reader, simple enough for its requirements, and consistent with nearby code.

Use comments for rationale, invariants, externally observable behavior, or non-obvious trade-offs—not a restatement of the code.

```go
// Gregorian leap years are not divisible by 100 unless divisible by 400.
leap := year%4 == 0 && (year%100 != 0 || year%400 == 0)
```

Prefer the language and standard library when they meet the need. Add a dependency when it meaningfully improves correctness, interoperability, or maintenance.

## Formatting and imports

- Format Go source with `gofmt`.
- Let the repository's formatter and linter configuration decide import grouping and any line-length policy. Do not manually wrap code merely to meet an arbitrary width.
- Follow the standard Go spelling convention: exported identifiers use `MixedCaps`; unexported identifiers use `mixedCaps`. Initialisms follow local and Go conventions (`ID`, `URL`, `HTTP`).
- Use lowercase package names without underscores. Choose a concise name describing the package's purpose; avoid catch-all packages such as `util` unless that is an established repository convention.

```go
import (
    "context"
    "fmt"

    "example.com/project/store"
)
```

## Naming and scope

Choose names that are precise in their local context without repeating the package, receiver, or obvious type.

```go
package yamlconfig

func Parse(input string) (*Config, error)
```

Use noun-like names for values and verb-like names for actions. `Get` is appropriate when it communicates an operation's semantics (for example, a lookup that can fail or fetch); do not add it mechanically.

Keep scopes small enough to make data flow obvious. Check `:=` in nested scopes carefully: it may declare a new variable instead of updating the value used later.

```go
func limit(ctx context.Context) (context.Context, func()) {
    ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
    return ctx, cancel
}
```

## Documentation and exported APIs

Document exported packages, types, functions, methods, and fields when their purpose or contract is not obvious from the declaration. For public APIs, state behavior callers need to rely on: ownership, mutation, error matching, cancellation, ordering, and concurrency guarantees where relevant.

Do not assume all read-only methods are safe for concurrent use. Say so when callers need that guarantee, and document any locking or ownership constraint that would otherwise surprise them.

Preserve compatibility for established exported APIs unless the change is explicitly intended to be breaking.

## Declarations and literals

Use `var` when the zero value is the useful initial state; use a composite literal when initial elements are known.

```go
var result bytes.Buffer
values := []int{2, 3, 5}
options := Config{Timeout: time.Second}
```

Use field names for struct literals outside the defining package; `go vet` can flag unkeyed external literals. For exported or long-lived literals in any package, keyed fields make additions and review safer. Positional literals can be clear for small, stable local structs.

Use `&T{...}` when constructing a pointer with known initial fields. `new(T)` is reasonable when the zero value itself is the desired pointer value.

## Control flow

Handle errors and exceptional conditions near their source; early returns often reduce nesting. Do not flatten control flow at the expense of obscuring the normal path. Group declarations when they represent one concept, not merely because they share a type.
