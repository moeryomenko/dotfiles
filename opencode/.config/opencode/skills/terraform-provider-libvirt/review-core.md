# Libvirt Provider Review Checklist

Review checklist for terraform-provider-libvirt code contributions.

## Checklist Categories

### 1. RNG Schema Compliance

Consult RNG schemas with:

```bash
grep -A 5 -B 5 '<element name="...">' /usr/share/libvirt/schemas/domain.rng
```

- [ ] Schema fields correspond to `/usr/share/libvirt/schemas/*.rng` definitions
- [ ] Element hierarchy matches RNG `interleave` structure
- [ ] Required vs optional fields match RNG definitions
- [ ] Enum values match RNG `choice` definitions
- [ ] Type constraints match RNG validation rules
- [ ] RNG schemas consulted via `grep -A 5 -B 5 '<element name="...">' /usr/share/libvirt/schemas/domain.rng`

### 2. Nested Attributes vs Blocks

- [ ] New schema uses nested attributes (`SingleNestedAttribute`, `ListNestedAttribute`)
- [ ] Blocks only used for backward compatibility (legacy resources: `os`, `features`, `cpu`, `clock`, `pm`, `create`, `destroy`) — these 7 legacy blocks are exempt from the "no blocks" rule
- [ ] No mixed attribute/block patterns on the same field

### 3. Field Read Semantics

- [ ] Computed-only fields: always read from API, never from plan
- [ ] Optional fields: only populated if user specified in plan
- [ ] Required fields: always present in state
- [ ] User input preserved on readback (libvirt normalizes values)

### 4. Codegen Compliance

- [ ] `make generate` has been run before committing
- [ ] Generated files (`internal/generated/*.gen.go`) are gitignored
- [ ] Manual schema changes don't conflict with codegen output
- [ ] Policy files (`internal/codegen/policy/`) correctly annotate field semantics

### 5. golibvirt API Usage

- [ ] Constants used instead of magic numbers (`DomainRunning`, not `1`)
- [ ] API errors handled gracefully (connection lost, timeout)
- [ ] XML parsing uses libvirtxml types, not raw string manipulation
- [ ] Connection lifecycle managed (connect/disconnect)

### 6. Testing

- [ ] Unit tests pass (`make test`)
- [ ] Acceptance tests pass (`make testacc` with `LIBVIRT_TEST_URI`)
- [ ] Sweepers prefixed test- cleanup after tests
- [ ] Regression tests in `internal/regression/` for known issues

### 7. Connection Transport

- [ ] URI parsing handles all transport types correctly
- [ ] SSH key/auth resolution is tested
- [ ] Connection timeout is configurable
- [ ] Reconnection logic handles transient failures
