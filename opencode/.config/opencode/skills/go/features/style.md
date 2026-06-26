# Go Style Guide

## Style Principles

Readable code attributes in order of importance (Google):

1. **Clarity**: The code's purpose is clear to the reader.
2. **Simplicity**: Accomplishes goal in the simplest way.
3. **Concision**: High signal-to-noise ratio.
4. **Maintainability**: Easy to modify correctly.
5. **Consistency**: Consistent with the broader codebase.

### Clarity

Clarity is viewed through the lens of the **reader**, not the author. Two facets:

- **What** is the code doing? Use descriptive names, commentary, whitespace.
- **Why** is it doing it? Explain nuances that aren't obvious from code.

Comments should explain **why**, not **what**:

```go
// Good: explains rationale, not mechanics
// Gregorian leap years aren't just year%4 == 0.
var (
    leap4   = year%4 == 0
    leap100 = year%100 == 0
    leap400 = year%400 == 0
)
leap := leap4 && (!leap100 || leap400)

// Bad: states the obvious
// Check if year is a leap year
leap := (year%4 == 0) && (!(year%100 == 0) || (year%400 == 0))
```

### Simplicity

**Least mechanism** (Google): Prefer the most standard tools. Core language constructs (channels, slices, maps, loops, structs) > standard library > external dependencies.

### Concision

Repetitive code obscures differences. Use table-driven tests to factor out common code. When code is similar to a common idiom but subtly different, intentionally "boost" the signal:

```go
// Calls attention to the subtle difference
if err := doSomething(); err == nil { // if NO error
    // ...
}
```

### Consistency

**Local consistency** (Google): Where the guide has nothing to say, authors are free to choose, unless code in close proximity takes a consistent stance. If a change would **worsen** an existing deviation, expose it in more API surfaces, or introduce a bug, then local consistency no longer applies.

## Formatting

- All Go source must conform to `gofmt` output.
- **No fixed line length** (Google). Prefer refactoring over line splitting.
- Uber recommends soft limit of 99 chars.
- Do NOT split a line before an indentation change or to make a string fit.

## MixedCaps

Go source uses `MixedCaps` / `mixedCaps` (camelCase), never underscores:

```go
const MaxLength = 100     // exported
var maxLength = 50        // unexported
```

## Naming (Google Philosophy)

Names should:
- **Not feel repetitive when used**: `Count` not `CountEntries` when type is `Entries`.
- **Take context into consideration**: A method on `User` can be `ID()` not `UserID()`.
- **Not repeat concepts already clear**: `ch := make(chan int)` not `channel := make(chan int)`.

### Omit Repetition from Names

```go
// Bad — repeats package name
package yamlconfig
func ParseYAMLConfig(input string) (*Config, error)

// Good
package yamlconfig
func Parse(input string) (*Config, error)
```

**Omit from names:**
- Types of inputs/outputs (when unambiguous)
- The type of a method's receiver
- Whether an input/output is a pointer

### Function Naming

- **Return something** → noun-like names. **Avoid `Get` prefix.**
- **Do something** → verb-like names.
- **Identical functions differing by type** → append type name: `ParseInt`, `ParseInt64`.

### Package Naming

- Lowercase, no underscores, not plural, not `util` / `common`.
- One cohesive idea per package (standard library is the model).

### Shadowing

Be careful with `:=` in nested scopes — it creates a new variable:

```go
// Bad: shadowing creates a new ctx only inside the if block
func (s *Server) innerHandler(ctx context.Context, req *pb.MyRequest) *pb.MyResponse {
    if *shortenDeadlines {
        ctx, cancel := context.WithTimeout(ctx, 3*time.Second) // shadows outer ctx
        defer cancel()
    }
    // BUG: ctx is the ORIGINAL, uncapped context here
}

// Good: use = to stomp (reassign) rather than shadow
func (s *Server) innerHandler(ctx context.Context, req *pb.MyRequest) *pb.MyResponse {
    if *shortenDeadlines {
        var cancel func()
        ctx, cancel = context.WithTimeout(ctx, 3*time.Second) // reassigns outer ctx
        defer cancel()
    }
    // ctx is the capped context here
}
```

## Imports

Two groups: standard library first, then everything else, separated by a blank line.

```go
import (
    "context"
    "fmt"

    "github.com/user/project/pkg"
    "go.uber.org/zap"
)
```

## Comments and Documentation

- Don't enumerate obvious parameters. Document what's error-prone or non-obvious.
- Context cancellation: implied behavior, don't restate. Document when behavior differs.
- Read-only operations are assumed safe for concurrent use (don't restate). Mutating operations are assumed NOT safe (don't restate).

```go
// Good — explains non-obvious behavior
// The provided data is used to interpolate the format string. If the data does
// not match the expected format verbs or the amount of data does not satisfy
// the format specification, the function will inline warnings about formatting
// errors into the output string as described by the Format errors section.
func Sprintf(format string, data ...any) string

// Document when context behavior differs from normal
// Run executes the worker's run loop.
// If the context is cancelled, Run returns a nil error.
func (Worker) Run(ctx context.Context) error

// Document non-obvious concurrency semantics
// Lookup returns the data associated with the key from the cache.
// This operation is not safe for concurrent use.
func (*Cache) Lookup(key string) (data []byte, ok bool)
```

## Variable Declarations

Use zero value when the value is empty but **ready for later use**:

```go
var (
    coords Point
    primes []int
)

// Common use: output variable for unmarshalling
var coords Point
if err := json.Unmarshal(data, &coords); err != nil { ... }
```

Use composite literals when you know initial elements:

```go
coords   = Point{X: x, Y: y}
primes   = []int{2, 3, 5, 7, 11}
captains = map[string]string{"Kirk": "James Tiberius"}
```

## Struct Initialization

- Use field names (enforced by `go vet`).
- Omit zero-value fields.
- Use `var user User` for all-zero structs (not `User{}`).
- Use `&T{...}` for references (not `new(T)`).

## Style Rules Summary

| Aspect | Guideline |
|--------|-----------|
| Line length | No fixed limit (Google). Soft 99 chars (Uber). |
| Case | `MixedCaps` / `mixedCaps`, never snake_case |
| Package names | Lowercase, no underscores, not plural |
| Import groups | Stdlib first, blank line separator |
| Group declarations | Group `const`, `var`, `type` by relation |
| Function ordering | Rough call order, exported first |
| Reduce nesting | Handle errors/special cases first, return early |
| Unnecessary else | Set default, override with if |
| Local variables | `:=` for values; `var` for zero values |
| Naked parameters | Use custom types or comments for unclear bool params |

## Cross-References

- For slices, maps, defer, channels, goroutines: load `idioms`
- For error patterns and panics: load `error-handling`
- For test conventions: load `testing`
- For linter configuration: load `linter-guide`
