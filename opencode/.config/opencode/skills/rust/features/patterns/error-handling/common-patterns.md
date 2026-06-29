# Error Handling Patterns

## Error → Design Question Mapping

| Pattern | Misguided Fix | Better Question |
|---------|---------------|-----------------|
| unwrap panics | "Use ?" | Is None/Err actually possible here? |
| Type mismatch on ? | "Use anyhow" | Are error types designed correctly? |
| Lost error context | "Add .context()" | What does the caller need to know? |
| Too many error variants | "Use Box<dyn Error>" | Is error granularity matching use? |

---

## Error Handling Decision Flowchart

```
Is failure expected?
├─ Yes → Is absence the only "failure"?
│        ├─ Yes → Option<T>
│        └─ No → Result<T, E>
│                 ├─ Library → thiserror
│                 └─ Application → anyhow
└─ No → Is it a bug?
        ├─ Yes → panic!, assert!, unreachable!
        └─ No → Consider if really unrecoverable

Use ? → Need context?
├─ Yes → .context("message")
└─ No → Plain ?
```

---

## Library vs Application Error Handling

| Context | Error Crate | Why |
|---------|-------------|-----|
| Library | `thiserror` | Typed errors for consumers |
| Application | `anyhow` | Ergonomic error handling |
| Mixed | Both | thiserror at boundaries, anyhow internally |

### Boundary Conversion Pattern

```rust
// Library layer: typed error
#[derive(thiserror::Error, Debug)]
pub enum ConfigError {
    #[error("missing key: {0}")]
    MissingKey(String),
    #[error("parse error: {0}")]
    Parse(#[from] toml::de::Error),
}

// Application layer: convert at boundary
use anyhow::{Context, Result};

fn load_config() -> Result<Config> {
    let raw = std::fs::read_to_string("config.toml")
        .context("failed to read config file")?;
    let config: Config = toml::from_str(&raw)
        .context("failed to parse config")?;
    Ok(config)
}
```

---

## Error Propagation with Context

### Basic Pattern

```rust
use anyhow::{Context, Result};

fn process_file(path: &str) -> Result<Output> {
    let content = std::fs::read_to_string(path)
        .with_context(|| format!("failed to read {}", path))?;

    let parsed: Data = serde_json::from_str(&content)
        .context("malformed JSON in input")?;

    let result = transform(parsed)
        .context("transform step failed")?;

    Ok(result)
}
```

### Context Placement Guidelines

- Add `.context()` at each fallible step that could fail independently
- Include the relevant inputs in the context message
- Use `.with_context()` (lazy) over `.context()` (eager) when the message requires allocation
- Don't add context for trivially clear operations like string parsing

---

## Common Error Handling Patterns

### Fallible Constructor

```rust
#[derive(Debug)]
struct Email(String);

impl Email {
    fn new(s: String) -> Result<Self, InvalidEmail> {
        if s.contains('@') {
            Ok(Self(s))
        } else {
            Err(InvalidEmail(s))
        }
    }
}
```

### Error Type with Multiple Sources

```rust
#[derive(thiserror::Error, Debug)]
pub enum ApiError {
    #[error("network error: {0}")]
    Network(#[from] reqwest::Error),
    #[error("parse error: {0}")]
    Parse(#[from] serde_json::Error),
    #[error("rate limited until {0:?}")]
    RateLimited(chrono::DateTime<chrono::Utc>),
}
```

### Result Alias

```rust
type Result<T> = std::result::Result<T, AppError>;

fn do_thing() -> Result<Value> {
    Ok(compute()?)
}
```

### Swallowing Errors Deliberately

```rust
// When error is expected and harmless
let _ = fs::remove_file("cache.tmp");  // Ignore if file doesn't exist

// When error is informative but non-critical
if let Err(e) = metrics::record(&event) {
    tracing::warn!("failed to record metric: {}", e);
}
```

### Unwrap/Except Usage Decision

```rust
// TEST/EXAMPLE: unwrap is fine
#[test]
fn test_parse() {
    let data = parse("valid").unwrap();
}

// INVARIANT HOLDS: expect with reason
let home = env::var("HOME").expect("HOME must be set");

// BUG/DEAD CODE: should never happen
let idx = match some_enum {
    A => 0,
    B => 1,
    // When new variant added, panic signals missing update
};
```

### Partial Errors with Iterator

```rust
// Collect partial results, don't fail on first error
let (successes, errors): (Vec<_>, Vec<_>) = items
    .into_iter()
    .map(|item| process(item))
    .partition(Result::is_ok);

// Or use itertools::partition_result
use itertools::Itertools;
let (successes, errors): (Vec<_>, Vec<_>) = items
    .into_iter()
    .map(|item| process(item))
    .partition_result();
```
