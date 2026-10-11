# Observability

Design telemetry around the operational questions the service or program must answer. Follow the repository's `tracing`/logging setup, sampling, privacy policy, and cardinality budget; emit structured events without installing global subscribers from library code.

## Events and spans

Use fields for data queried or correlated downstream, and messages for human meaning:

```rust
tracing::info!(user_id = user.id, request_id = %request_id, "user authenticated");
```

`#[tracing::instrument]` creates and enters a span around a function or async future. It records selected arguments by default, so skip or redact sensitive and high-cardinality values. It does not automatically record duration, return values, or errors unless the subscriber/layer and macro options are configured to do so.

```rust
#[tracing::instrument(skip(password), err)]
fn authenticate(user: &str, password: &str) -> Result<Session, AuthError> {
    verify(user, password)
}
```

The `err` option records an event when the result is an error; choose return-value recording deliberately because it can expose large or sensitive data.

## Boundaries and levels

Choose levels according to the team's alerting and investigation practices. Add context as a failure crosses a meaningful ownership or semantic boundary, then record/report it at a deliberate handling boundary rather than logging every propagation layer.

Libraries may emit through `tracing` or `log`; applications own subscribers, filtering, output, and exporter configuration. Never rely on telemetry as the only integrity or audit record, and avoid secrets, credentials, personal data, and unbounded-cardinality fields unless policy explicitly permits them.

## Load next

- Error propagation: `error-handling.md`
- Async task context: `async.md`
- CLI or web boundaries: `../domain-cli/SKILL.md`, `../domain-web/SKILL.md`
