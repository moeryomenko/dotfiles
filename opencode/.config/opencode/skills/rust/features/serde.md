# Serde (MEDIUM)

## Match External Naming Convention with `rename_all`

```rust
#[derive(Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
struct Config {
    max_connections: u32,  // serializes as "max_connections"
}
```

Common values: `"camelCase"`, `"snake_case"`, `"kebab-case"`, `"PascalCase"`, `"SCREAMING_SNAKE_CASE"`.

## Use `#[serde(default)]` for Optional and Backward-Compatible Fields

```rust
#[derive(Deserialize)]
struct Config {
    #[serde(default)]
    timeout: Duration,  // Uses Default::default() if missing
    #[serde(default = "default_host")]
    host: String,
}

fn default_host() -> String { "localhost".into() }
```

## Omit Empty Fields with `skip_serializing_if`

```rust
#[derive(Serialize)]
struct Response {
    data: Vec<Item>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<String>,
}
```

## Inline Nested Structs or Capture Extra Keys with `flatten`

```rust
#[derive(Deserialize)]
struct Params {
    #[serde(flatten)]
    extra: HashMap<String, Value>,
}
```

## Choose Enum Tagging Deliberately

```rust
// Internally tagged (default): {"type": "A", "value": 1}
#[serde(tag = "type")]

// Adjacently tagged: {"type": "A", "content": {"value": 1}}
#[serde(tag = "type", content = "content")]

// Untagged: tries each variant in order
#[serde(untagged)]
```

## Reject Unexpected Keys with `deny_unknown_fields`

```rust
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct StrictConfig { /* ... */ }
```

## Customize Field Serialization with `with`

```rust
#[serde(with = "serde_bytes")]
    data: Vec<u8>,
```

## Validate While Deserializing with `try_from`

```rust
#[derive(Deserialize)]
struct RawEmail(String);

impl TryFrom<RawEmail> for Email {
    type Error = String;
    fn try_from(raw: RawEmail) -> Result<Self, Self::Error> {
        if raw.0.contains('@') { Ok(Email(raw.0)) }
        else { Err("invalid email".into()) }
    }
}

#[derive(Deserialize)]
struct User {
    #[serde(try_from = "RawEmail")]
    email: Email,
}
```

## Cross-References

- For API design for serde: load `api-design`
- For type safety: load `type-safety`
