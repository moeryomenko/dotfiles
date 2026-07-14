# Testing Patterns for terraform-inventory

Test fixtures, CLI testing patterns, and verification approaches.

## Test Structure

```go
func TestParseState12(t *testing.T) {
  data := loadFixture(t, "fixtures/state_v12.json")
  resources, err := parseState(data)
  if err != nil {
    t.Fatal(err)
  }
  if len(resources) == 0 {
    t.Fatal("expected resources from 0.12+ state")
  }
}
```

## Test Fixtures

```
fixtures/
├── state_v4.json              # 0.12+ state format (version 4)
├── state_v4_multiple.json     # Multiple resources, count/for_each
├── state_v4_with_outputs.json # State with outputs
├── state_v3.json              # Pre-0.12 format (version 3)
└── state_empty.json           # Empty state (no resources)
```

### Fixture Example

Create minimal state fixtures for specific test scenarios:

```json
{
  "version": 4,
  "terraform_version": "1.9.0",
  "serial": 1,
  "lineage": "test-lineage",
  "values": {
    "root_module": {
      "resources": [
        {
          "address": "aws_instance.test",
          "mode": "managed",
          "type": "aws_instance",
          "name": "test",
          "provider_name": "aws",
          "values": {
            "id": "i-1234",
            "public_ip": "203.0.113.1",
            "tags": {
              "Name": "test-instance"
            }
          }
        }
      ]
    }
  }
}
```

## CLI Testing

### Capturing Output with bytes.Buffer

Use `bytes.Buffer` to capture CLI output from a function or when testing the
main entry point with an `io.Writer` interface:

```go
func TestListOutput(t *testing.T) {
  var buf bytes.Buffer
  app := &CLIApp{
    Out: &buf,
    Err: os.Stderr,
  }

  err := app.Run([]string{"--list", "fixtures/state_v4.json"})
  if err != nil {
    t.Fatal(err)
  }

  var inventory map[string]interface{}
  if err := json.Unmarshal(buf.Bytes(), &inventory); err != nil {
    t.Fatal(err)
  }
}
```

### Exit Code Verification

Use `exec.Command` with `cmd.Run()` and check the exit code via the error type:

```go
func TestExitCodeOnBadState(t *testing.T) {
  cmd := exec.Command("go", "run", ".", "--list", "fixtures/nonexistent.json")
  err := cmd.Run()

  if exitErr, ok := err.(*exec.ExitError); ok {
    if exitErr.ExitCode() != 1 {
      t.Fatalf("expected exit code 1, got %d", exitErr.ExitCode())
    }
  } else if err != nil {
    t.Fatalf("unexpected error type: %T", err)
  } else {
    t.Fatal("expected error, got none")
  }
}
```

### Stderr Capture

Combine `bytes.Buffer` for stderr with `cmd.Output()` for stdout:

```go
func TestStderrOnWarning(t *testing.T) {
  cmd := exec.Command("go", "run", ".", "--list", "fixtures/state_bad.json")
  var stderr bytes.Buffer
  cmd.Stderr = &stderr

  out, err := cmd.Output()
  if err != nil {
    // Log stderr even when command fails
    t.Logf("stderr: %s", stderr.String())
    t.Fatal(err)
  }

  if stderr.Len() > 0 {
    t.Logf("warnings on stderr:\n%s", stderr.String())
  }
}
```

### Table-Driven CLI Tests

Test multiple CLI scenarios with a single table:

```go
func TestCLIScenarios(t *testing.T) {
  tests := []struct {
    name      string
    args      []string
    fixture   string
    wantCount int
    wantCode  int
    checkFn   func(t *testing.T, stdout, stderr string)
  }{
    {
      name:      "list basic state",
      args:      []string{"--list"},
      fixture:   "fixtures/state_v4.json",
      wantCount: 2,
      wantCode:  0,
    },
    {
      name:      "INI output format",
      args:      []string{"--inventory"},
      fixture:   "fixtures/state_v4.json",
      wantCount: 2,
      wantCode:  0,
      checkFn: func(t *testing.T, stdout, stderr string) {
        if !strings.HasPrefix(stdout, "[all]") {
          t.Errorf("expected INI format starting with [all], got:\n%s", stdout)
        }
      },
    },
    {
      name:      "host output",
      args:      []string{"--host", "web-0"},
      fixture:   "fixtures/state_v4.json",
      wantCount: 1,
      wantCode:  0,
    },
    {
      name:      "missing state file",
      args:      []string{"--list"},
      fixture:   "fixtures/nonexistent.json",
      wantCode:  1,
    },
  }

  for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
      args := append(tt.args, tt.fixture)
      cmd := exec.Command("go", "run", ".", args...)
      var stdout, stderr bytes.Buffer
      cmd.Stdout = &stdout
      cmd.Stderr = &stderr

      exitCode := 0
      if err := cmd.Run(); err != nil {
        if exitErr, ok := err.(*exec.ExitError); ok {
          exitCode = exitErr.ExitCode()
        } else {
          t.Fatal(err)
        }
      }

      if exitCode != tt.wantCode {
        t.Fatalf("exit code: got %d, want %d", exitCode, tt.wantCode)
      }

      if tt.checkFn != nil {
        tt.checkFn(t, stdout.String(), stderr.String())
      }
    })
  }
}
```

## Test Scenarios

| Scenario | Input | Expected output |
|----------|-------|----------------|
| Basic 0.12+ state | `fixtures/state_v4.json` | Correct hosts + groups |
| Pre-0.12 state | `fixtures/state_v3.json` | Correct hosts + groups |
| Multiple resources | `fixtures/state_v4_multiple.json` | Multiple group entries |
| With outputs | `fixtures/state_v4_with_outputs.json` | Outputs as all.vars |
| Empty state | `fixtures/state_empty.json` | Empty inventory |
| Host output | `--host web-0` with state | Host attributes |
| INI output | `--inventory` flag | INI format |
| Binary detection | No args with state file | Auto-detect tofu/terraform |
