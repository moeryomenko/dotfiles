# Go Linter Guide

Treat linting as a repository policy, not a universal list of rules. Start with a small correctness baseline, then add checks that match the codebase's APIs, dependencies, security posture, generated code, and review capacity. A clean first run and an agreed remediation plan are more valuable than enabling every available linter.

## Establish a baseline

Use `gofmt` and `go test ./...` regardless of a linter. A practical Go correctness baseline normally includes:

| Tool or linter | Value |
|---|---|
| `govet` | suspicious constructs recognized by `go vet` |
| `staticcheck` | high-value static analysis, including simplifications and correctness checks |
| `errcheck` | ignored returned errors |
| `ineffassign` | assignments that cannot affect a result |
| `unused` | unused code where its analysis scope supports it |
| `goimports` or the repository formatter | import organization and formatting |

For current `golangci-lint` releases that support the v2 configuration format, an intentionally small starting point is:

```yaml
version: "2"

linters:
  default: standard
  enable:
    - errcheck
    - staticcheck

formatters:
  enable:
    - gofmt
    - goimports
```

Do not copy this into a repository using an older `golangci-lint` version without checking that version's configuration schema. Inspect the installed version, preserve existing policy, and validate a configuration by running its documented config-verification command (where available) followed by:

```bash
golangci-lint run ./...
```

Pin the linter and CI action versions according to the repository's dependency-update policy; avoid an unreviewed `latest` in reproducible CI.

## Add targeted checks

Enable a linter because it catches a failure mode the project has, and configure it with a clear ownership policy.

| Concern | Candidates | When it fits |
|---|---|---|
| Error contracts | `errorlint`, `wrapcheck` | APIs with deliberate wrapping and matching rules; tune to avoid forcing wrappers at translation boundaries |
| Context propagation | `contextcheck`, `noctx` | request-driven code; `noctx` can be noisy for intentionally context-free APIs |
| HTTP and SQL cleanup | `bodyclose`, `rowserrcheck`, `sqlclosecheck` | repositories using those APIs |
| Security | `gosec` | security-reviewed services, with documented suppressions for accepted findings |
| Structured logging | `loggercheck`, `sloglint` | a repository committed to the corresponding logging style |
| Tests | `thelper`, `paralleltest`, `tenv`, `testifylint` | only for the testing frameworks and parallelization policy actually used |
| Module policy | `gomoddirectives`, `gomodguard`, `depguard` | controlled dependency or module governance |
| Generated schemas and metrics | `protogetter`, `promlinter`, `tagliatelle` | repositories that own those artifacts |
| Complexity or style | `gocritic`, `revive`, `cyclop`, `funlen`, `dupl` | teams that have calibrated thresholds and will maintain exceptions |

`copyloopvar` is useful when the module targets Go 1.22 or later, where redundant loop-variable copies are often unnecessary. It is not a replacement for reviewing closure lifetimes, synchronization, or compatibility with older module language versions.

## Avoid noisy policy by default

Line-length rules, naming restrictions, mandatory comment punctuation, declaration order, function size, magic-number bans, global bans, and blanket interface-return restrictions are style choices. Enable them only after the team agrees on the rule, its exceptions, and how existing code will be migrated.

Do not rely on `govet` as a general shadowing checker: shadow analysis is not part of ordinary default `go vet` behavior. Likewise, `fatcontext` addresses context growth in loops; it does not detect `t.Fatal` in a worker goroutine. Review goroutine test failures with the testing guidance and synchronization-aware tooling.

## CI rollout

Run the same pinned linter version locally and in CI. During adoption, either fix findings or use narrowly scoped, explained suppressions; do not silently suppress an entire linter to make the first run pass. Gate only the directories and build tags CI actually tests, and include generated-code handling explicitly in the configuration.
