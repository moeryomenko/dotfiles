# Serde

Treat serialized data as an external compatibility contract. Inspect the actual format, versioning policy, untrusted-input limits, and enabled Serde features before choosing a representation.

## Fields and defaults

Use `rename` or `rename_all` only to match an established wire format. `Option<T>` naturally accepts an absent field; use `#[serde(default)]` when a non-optional field has a deliberate compatible default.

```rust
#[derive(serde::Deserialize)]
#[serde(rename_all = "camelCase")]
struct Config {
    #[serde(default = "default_timeout_ms")]
    timeout_ms: u64,
    endpoint: Option<String>,
}

fn default_timeout_ms() -> u64 { 5_000 }
```

`skip_serializing_if` changes output compatibility, so use it only when omission and the alternate value are intentionally equivalent to consumers.

## Enums and conversion

Externally tagged enums are the default Serde representation. `#[serde(tag = "type")]` selects *internally* tagged representation; adding `content` selects adjacently tagged representation; `untagged` tries variants in order and can be ambiguous or slower.

Validate a deserialized representation at a conversion boundary. `try_from` is a container attribute, not a field attribute:

```rust
#[derive(serde::Deserialize)]
struct RawEmail(String);

struct Email(String);

impl TryFrom<RawEmail> for Email {
    type Error = &'static str;

    fn try_from(raw: RawEmail) -> Result<Self, Self::Error> {
        raw.0.contains('@').then_some(Self(raw.0)).ok_or("invalid email")
    }
}

#[derive(serde::Deserialize)]
#[serde(try_from = "RawEmail")]
struct Contact(Email);

impl TryFrom<RawEmail> for Contact {
    type Error = &'static str;

    fn try_from(raw: RawEmail) -> Result<Self, Self::Error> {
        Ok(Self(Email::try_from(raw)?))
    }
}
```

## Unknown fields

`#[serde(flatten)]` can merge nested fields or capture extra keys. It is incompatible in important cases with `deny_unknown_fields`; choose strict rejection or forward-compatible capture deliberately and verify the selected format's behavior.

Deserialization validates syntax and shape, not authorization, semantic invariants, resource limits, or migration policy.

## Load next

- Public wire contracts: `api-design.md`
- Domain invariants: `type-safety.md`
- Error boundaries: `error-handling.md`
