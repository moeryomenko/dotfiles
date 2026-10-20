# Go Error Handling

## Error ownership

Return errors from libraries and lower-level operations so the layer with user-facing context can decide whether to retry, translate, report, or terminate. Avoid logging an error and returning it unchanged unless the layer is the designated reporting boundary; otherwise callers commonly produce duplicate logs.

Handle an error where it can be resolved. Otherwise add concise operation context and propagate it.

```go
user, err := getUser(id)
if err != nil {
    return fmt.Errorf("get user %q: %w", id, err)
}
```

## Choosing an error representation

| Caller needs | Prefer |
|---|---|
| Static text only | `errors.New` |
| Dynamic text only | `fmt.Errorf` |
| Stable category callers can match | exported or package-local sentinel error |
| Structured dynamic details callers need | a custom error type |
| Dynamic context around a matchable cause | `fmt.Errorf` with `%w` |

```go
var ErrNotFound = errors.New("not found")

type FieldError struct {
    Field string
    Err   error
}

func (e *FieldError) Error() string { return fmt.Sprintf("%s: %v", e.Field, e.Err) }
func (e *FieldError) Unwrap() error { return e.Err }
```

Use `ErrXxx` and `errXxx` consistently with the package's naming style. Expose only error values and types that callers are intended to inspect.

## Wrapping is an API decision

Use `%w` when callers should retain the ability to use `errors.Is` or `errors.As` on the cause. That choice exposes an inspection contract: changing the wrapped error later can be a compatibility change.

Use `%v`, or construct a different error, when translating an implementation detail at a boundary that callers should not depend on.

```go
// The caller may distinguish unavailable storage.
return fmt.Errorf("load profile: %w", err)

// The service intentionally exposes a domain error instead.
return ErrUnavailable
```

Place context where it reads naturally. The position of `%w` affects text, not matching behavior; optimize for a stable, useful message.

Match programmatically rather than parsing messages.

```go
if errors.Is(err, fs.ErrNotExist) {
    return nil
}

var pathErr *fs.PathError
if errors.As(err, &pathErr) {
    return fmt.Errorf("read configuration %q: %w", pathErr.Path, err)
}
```

## Reporting and process exit

At an executable boundary, turn a returned error into the repository's chosen logging or user-output format and a status code. At most one layer should normally emit the final diagnostic.

```go
func main() {
    if err := run(); err != nil {
        log.Print(err)
        os.Exit(1)
    }
}
```

`log.Fatal` and `os.Exit` bypass deferred functions. Do not use them in libraries, handlers, tests, or code that still owns cleanup.

If constructing expensive log arguments, use the selected logging library's enabled-level API before doing that work. Do not assume a particular logging facade, method name, buffering behavior, or flush cost.

## Panics and recovery

Use returned errors for expected failures. A panic can be appropriate for a broken internal invariant or documented programmer misuse; it is not a substitute for validating external input.

Recover only when a boundary can safely contain a known panic protocol, such as converting an internal parser sentinel into an error. Preserve unknown panics by re-panicking them.

```go
func Parse(input string) (node *Node, err error) {
    defer func() {
        if recovered := recover(); recovered != nil {
            syntaxErr, ok := recovered.(*syntaxError)
            if !ok {
                panic(recovered)
            }
            err = fmt.Errorf("parse: %w", syntaxErr)
        }
    }()
    return parseInternal(input), nil
}
```
