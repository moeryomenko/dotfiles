# CI/CD Integration

Continuous integration and delivery patterns for Bash projects. Covers pipeline
configuration for GitHub Actions and GitLab CI, pre-commit hooks, local
automation via Makefile, shell matrix testing, containerized environments,
secrets scanning, automated releases, and dependency management.

---

## 1. GitHub Actions

### Standard Lint-Test Pipeline

```yaml
# .github/workflows/ci.yml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  SHELLCHECK_OPTS: -x  # follow source directives
  SHFMT_OPTS: -i 2 -ci -sr

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install tools
        run: |
          sudo apt-get update -qq
          sudo apt-get install -y -qq shellcheck shfmt

      - name: ShellCheck
        run: shellcheck $(find . -name '*.sh' -type f)

      - name: shfmt check
        run: shfmt -d -i 2 -ci -sr $(find . -name '*.sh' -type f)

  test:
    name: Test (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v4

      - name: Install BATS
        run: |
          if [[ "$RUNNER_OS" == "macOS" ]]; then
            brew install bats-core
          else
            sudo apt-get update -qq
            sudo apt-get install -y -qq bats
          fi

      - name: Run tests
        run: bats tests/
```

[Check] GitHub Actions workflow covers shellcheck, shfmt, and bats test matrix across ubuntu and macos

### Full Matrix Including Shell Versions

```yaml
# .github/workflows/test-matrix.yml
name: Shell Matrix Test
on: [push, pull_request]

jobs:
  shell-matrix:
    name: Test
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        shell:
          - bash-4.4
          - bash-5.0
          - bash-5.1
          - bash-5.2
          - dash
          - sh
    container:
      image: >
        ${{
          matrix.shell == 'sh' && 'ubuntu:latest' ||
          matrix.shell == 'dash' && 'ubuntu:latest' ||
          format('mvdan/{0}:latest', matrix.shell)
        }}
    steps:
      - uses: actions/checkout@v4

      - name: Install BATS (dash/sh)
        if: matrix.shell == 'dash' || matrix.shell == 'sh'
        run: |
          apt-get update -qq
          apt-get install -y -qq bats

      - name: Run tests with ${{ matrix.shell }}
        env:
          BASH_TEST_SHELL: >
            ${{
              matrix.shell == 'sh' && '/bin/sh' ||
              matrix.shell == 'dash' && '/bin/dash' ||
              startsWith(matrix.shell, 'bash') &&
                format('/usr/local/bin/{0}', matrix.shell) ||
              '/bin/bash'
            }}
        run: bats tests/
```

[Check] Shell matrix covers bash 4.4, 5.0, 5.1, 5.2, dash, and sh

---

## 2. GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - lint
  - test

variables:
  SHELLCHECK_OPTS: "-x"
  SHFMT_OPTS: "-i 2 -ci -sr"

shell-lint:
  stage: lint
  image: ubuntu:latest
  before_script:
    - apt-get update -qq
    - apt-get install -y -qq shellcheck shfmt
  script:
    - shellcheck $(find . -name '*.sh' -type f)
    - shfmt -d -i 2 -ci -sr $(find . -name '*.sh' -type f)

shell-test-ubuntu:
  stage: test
  image: ubuntu:latest
  parallel:
    matrix:
      - SHELL: [bash, dash, sh]
  before_script:
    - apt-get update -qq
    - apt-get install -y -qq bats
  script:
    - bats tests/

shell-test-containerized:
  stage: test
  parallel:
    matrix:
      - IMAGE:
          - mvdan/bash-4.4:latest
          - mvdan/bash-5.0:latest
          - mvdan/bash-5.1:latest
          - mvdan/bash-5.2:latest
  image: $IMAGE
  before_script:
    - apt-get update -qq
    - apt-get install -y -qq bats
  script:
    - bats tests/
```

[Check] GitLab CI covers shell lint stage, test stage, and parallel execution across shells

---

## 3. Pre-Commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/shellcheck-py/shellcheck-py
    rev: v0.10.0.1
    hooks:
      - id: shellcheck
        args: ["-x"]
        files: \.sh$

  - repo: https://github.com/scop/pre-commit-shfmt
    rev: v3.10.0-1
    hooks:
      - id: shfmt
        args: ["-i", "2", "-ci", "-sr", "-w"]

  - repo: https://github.com/openstack/bashate
    rev: 2.1.1
    hooks:
      - id: bashate
        args: ["--ignore=E006"]
        files: \.sh$

  - repo: https://github.com/editorconfig-checker/editorconfig-checker.python
    rev: 3.0.3
    hooks:
      - id: editorconfig-checker
        files: \.(sh|bash)$
```

### checkbashisms

checkbashisms detects Bash-specific syntax in POSIX sh scripts:

```yaml
  - repo: https://github.com/ferdinandyb/checkbashisms-precommit
    rev: v2.24.1
    hooks:
      - id: checkbashisms
        args: ["--force"]
        files: \.sh$
```

### Additional Utility Hooks

```yaml
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: check-executables-have-shebangs
        files: \.sh$
      - id: check-shebang-scripts-are-executable
        files: \.sh$
      - id: check-builtin-literals
      - id: check-case-conflict
```

[Check] Pre-commit config covers shellcheck, shfmt, bashate, checkbashisms

---

## 4. Makefile Targets

```makefile
# Makefile — Bash project CI targets
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

# Configuration
SHFMT_FLAGS    ?= -i 2 -ci -sr
SHELLCHECK_X   ?= -x
TEST_SHELLS    ?= /bin/bash /bin/dash /bin/sh
BATS_FLAGS     ?= --timing --print-output-on-failure

# Source discovery
SH_SRCS    := $(shell find . -name '*.sh' -type f)
TEST_FILES := $(shell find tests/ -name '*.bats' -type f 2>/dev/null)

.PHONY: lint format test test-all check
.PHONY: lint-shellcheck lint-shfmt fmt actionlint-check

## lint              — Run all linters
lint: lint-shellcheck lint-shfmt

## lint-shellcheck   — Run ShellCheck on all shell scripts
lint-shellcheck:
	shellcheck $(SHELLCHECK_X) $(SH_SRCS)

## lint-shfmt        — Check formatting with shfmt
lint-shfmt:
	shfmt -d $(SHFMT_FLAGS) $(SH_SRCS)

## format            — Auto-format all shell scripts with shfmt
format:
	shfmt -w $(SHFMT_FLAGS) $(SH_SRCS)

## fmt               — Alias for format
fmt: format

## test              — Run bats tests with default shell
test:
	bats $(BATS_FLAGS) $(TEST_FILES)

## test-all          — Run bats tests across all configured shells
test-all:
	@for shell in $(TEST_SHELLS); do \
		echo "=== Testing with $$shell ==="; \
		BATS_SHELL=$$shell bats $(BATS_FLAGS) $(TEST_FILES) || exit 1; \
	done

## check             — Combine lint + test in one command
check: lint test

## test-shell        — Run tests against a specific shell
test-shell:
	BATS_SHELL=$(SHELL) bats $(BATS_FLAGS) $(TEST_FILES)

## shellcheck-report — Generate ShellCheck JSON report
shellcheck-report:
	shellcheck -f json $(SHELLCHECK_X) $(SH_SRCS) > shellcheck-report.json

## actionlint-check  — Validate GitHub Actions workflows
actionlint-check:
	actionlint
```

[Check] Makefile targets: lint, format, test, test-all, check, actionlint-check

---

## 5. Matrix Testing Across Shells

### BATS Shell Selection

BATS uses the shell specified by the `SHELL` environment variable or the
shebang in `.bats` files:

```bash
# Run tests with a specific shell
SHELL=/bin/bash-5.2 bats tests/
SHELL=/bin/dash bats tests/
SHELL=/bin/sh bats tests/
```

### Recommended Test Runner

```bash
# tests/run-with-shells.sh — suite runner across multiple shells
#!/bin/bash
set -euo pipefail

SHELLS=(
  /bin/bash
  /bin/dash
  /bin/sh
  /usr/local/bin/bash-4.4
  /usr/local/bin/bash-5.0
  /usr/local/bin/bash-5.1
  /usr/local/bin/bash-5.2
)

fail=0
for shell in "${SHELLS[@]}"; do
  if [[ ! -x "$shell" ]]; then
    echo "SKIP: $shell not installed"
    continue
  fi
  echo "=== Testing with $shell ==="
  if ! SHELL="$shell" bats tests/; then
    echo "FAIL: $shell"
    fail=1
  fi
done
exit $fail
```

### CI Integration

```yaml
  shell-matrix:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        shell: [/bin/bash, /bin/dash, /bin/sh]
    steps:
      - uses: actions/checkout@v4
      - name: Test with ${{ matrix.shell }}
        env:
          SHELL: ${{ matrix.shell }}
        run: SHELL=${{ matrix.shell }} bats tests/
```

[Check] Matrix testing supports bash 4.4, 5.0, 5.1, 5.2, dash, and sh

---

## 6. Containerized Testing

### Docker Images for Specific Shell Versions

Use pre-built images from `mvdan/` for exact bash versions:

```dockerfile
# tests/Dockerfile.bash-5.2
FROM mvdan/bash-5.2:latest

RUN apk add --no-cache bash bats

COPY . /work
WORKDIR /work

CMD ["bash", "-c", "SHELL=/usr/local/bin/bash-5.2 bats tests/"]
```

```bash
# Build and run
docker build -t bash-test -f tests/Dockerfile.bash-5.2 .
docker run --rm bash-test

# Run all shell Dockerfiles
for f in tests/Dockerfile.bash-*; do
  tag=$(echo "$f" | sed 's|tests/Dockerfile.||')
  docker build -t "$tag" -f "$f" .
  docker run --rm "$tag"
done
```

### Docker Compose for Full Matrix

```yaml
# tests/docker-compose.yml
version: "3.9"
services:
  bash-44:
    build:
      context: ..
      dockerfile: tests/Dockerfile.bash-4.4
  bash-50:
    build:
      context: ..
      dockerfile: tests/Dockerfile.bash-5.0
  bash-51:
    build:
      context: ..
      dockerfile: tests/Dockerfile.bash-5.1
  bash-52:
    build:
      context: ..
      dockerfile: tests/Dockerfile.bash-5.2
  dash:
    image: ubuntu:latest
    working_dir: /work
    command: >
      bash -c "apt-get update -qq && apt-get install -y -qq bats &&
               SHELL=/bin/dash bats tests/"
    volumes:
      - ..:/work
  posix-sh:
    image: ubuntu:latest
    working_dir: /work
    command: >
      bash -c "apt-get update -qq && apt-get install -y -qq bats &&
               bats tests/"
    volumes:
      - ..:/work
```

```bash
# Run full matrix
docker compose -f tests/docker-compose.yml up --abort-on-container-exit
```

### GitHub Actions Container Job

```yaml
  container-test:
    runs-on: ubuntu-latest
    container:
      image: mvdan/bash-5.2:latest
    steps:
      - uses: actions/checkout@v4
      - name: Install BATS
        run: apk add --no-cache bash bats
      - name: Run tests
        run: bats tests/
```

[Check] Containerized testing uses Docker for reproducible bash versions

---

## 7. Actionlint

### GitHub Actions Workflow Validation

```yaml
# .github/workflows/actionlint.yml
name: Actionlint
on:
  push:
    branches: [main]
    paths:
      - '.github/workflows/**'
  pull_request:
    paths:
      - '.github/workflows/**'

jobs:
  actionlint:
    name: Validate workflows
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Download actionlint
        run: |
          bash <(curl -sS \
            https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash)
          echo "./" >> $GITHUB_PATH

      - name: Run actionlint
        run: actionlint -color

      - name: Lint with shellcheck integration
        run: actionlint -color -shellcheck=
```

### Makefile Integration

```makefile
## actionlint-install — Install latest actionlint
actionlint-install:
	bash <(curl -sS https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash)

## actionlint-check — Validate all GitHub Actions workflows
actionlint-check:
	actionlint -color
```

[Check] Actionlint validates GitHub Actions workflows

---

## 8. Automated Releases

### GitHub Actions Release Pipeline

```yaml
# .github/workflows/release.yml
name: Release
on:
  push:
    tags:
      - 'v*.*.*'

permissions:
  contents: write

jobs:
  release:
    name: Create Release
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Generate changelog
        id: changelog
        run: |
          PREV_TAG=$(git tag --sort=-v:refname | head -2 | tail -1)
          if [[ -z "$PREV_TAG" ]]; then
            echo "changelog=Initial release" >> "$GITHUB_OUTPUT"
          else
            {
              echo "changelog<<EOF"
              git log "$PREV_TAG..HEAD" --oneline --no-decorate
              echo "EOF"
            } >> "$GITHUB_OUTPUT"
          fi

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          body: ${{ steps.changelog.outputs.changelog }}
          make_latest: true
```

### Semver Tagging

```bash
# Create and push a version tag
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3

# List tags sorted by version
git tag --sort=-v:refname

# Generate changelog between releases
git log $(git tag --sort=-v:refname | head -1)..HEAD --oneline --no-decorate
```

### Makefile Release Targets

```makefile
VERSION   ?= $(shell git describe --tags --always 2>/dev/null || echo "0.0.0")
CHANGELOG ?= CHANGELOG.md

.PHONY: tag changelog

## tag          — Create and push a version tag (usage: make tag VERSION=v1.2.3)
tag:
	@if echo "$(VERSION)" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+$$'; then \
		git tag -a "$(VERSION)" -m "Release $(VERSION)"; \
		git push origin "$(VERSION)"; \
	else \
		echo "ERROR: VERSION must match vX.Y.Z (got: $(VERSION))"; \
		exit 1; \
	fi

## changelog    — Generate changelog from git history
changelog:
	@previous=$$(git tag --sort=-v:refname | head -2 | tail -1); \
	if [[ -z "$$previous" ]]; then \
		git log --oneline --no-decorate > $(CHANGELOG); \
	else \
		git log "$$previous..HEAD" --oneline --no-decorate > $(CHANGELOG); \
	fi; \
	echo "Wrote $(CHANGELOG)"
```

[Check] Automated releases support version tagging and changelog generation

---

## 9. Coverage Reporting

### kcov (Recommended)

[kcov](https://github.com/SimonKagstrom/kcov) instruments shell scripts to
produce line and branch coverage:

```bash
# Install kcov
# Ubuntu: sudo apt-get install kcov
# macOS:  brew install kcov

# Run tests with coverage
kcov --include-path=./src \
     --exclude-pattern=tests,fixtures \
     /tmp/coverage \
     bats tests/

# Open HTML report
open /tmp/coverage/index.html

# JSON report (for CI)
kcov --include-path=./src \
     --exclude-pattern=tests,fixtures \
     --coveralls-id=ci \
     /tmp/coverage \
     bats tests/
```

### GitHub Actions Coverage Step

```yaml
  coverage:
    name: Coverage
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install kcov
        run: sudo apt-get install -y -qq kcov

      - name: Run tests with coverage
        run: |
          mkdir -p /tmp/coverage
          kcov --include-path=. \
               --exclude-pattern=tests,fixtures \
               /tmp/coverage \
               bats tests/

      - name: Upload coverage artifact
        uses: actions/upload-artifact@v4
        with:
          name: coverage-report
          path: /tmp/coverage/

      - name: Upload to Codecov
        uses: codecov/codecov-action@v5
        with:
          directory: /tmp/coverage/
          flags: shell
```

### shcov (Python-based)

```bash
# Install
pip install shcov

# Collect coverage
shcov -- bash tests/run-tests.sh

# Generate report
shcov-report coverage.json
```

[Check] Coverage reporting available with kcov and shcov

---

## 10. CodeQL Scanning

### GitHub Advanced Security for Shell

```yaml
# .github/workflows/codeql.yml
name: CodeQL
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 6 * * 1'

jobs:
  analyze:
    name: Analyze
    runs-on: ubuntu-latest
    permissions:
      security-events: write
      actions: read
    steps:
      - uses: actions/checkout@v4

      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: actions
          queries: security-extended,security-and-quality

      - name: Autobuild
        uses: github/codeql-action/autobuild@v3

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3
```

[Check] CodeQL scanning configured for shell scripts

---

## 11. Secrets Detection

### Gitleaks

```yaml
# .github/workflows/secrets-scan.yml
name: Secrets Scan
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  gitleaks:
    name: Gitleaks
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### TruffleHog

```yaml
  trufflehog:
    name: TruffleHog
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run trufflehog
        uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified
```

### Pre-Commit Integration

```yaml
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks-docker

  - repo: https://github.com/trufflesecurity/trufflehog
    rev: v3.82.0
    hooks:
      - id: trufflehog
        args: ["--only-verified", "--no-update"]
```

### Local Usage

```bash
# Scan repository with gitleaks
gitleaks detect --source . -v

# Scan with trufflehog
trufflehog git file://. --only-verified

# Run via pre-commit
pre-commit run gitleaks-docker
pre-commit run trufflehog
```

[Check] Secrets detection covers gitleaks and trufflehog

---

## 12. Dependabot and Renovate

### Dependabot Configuration

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: weekly
      day: monday
      time: "06:00"
    labels:
      - "dependencies"
      - "github-actions"
    commit-message:
      prefix: "ci"
      include: "scope"
    groups:
      actions:
        patterns:
          - "*"

  - package-ecosystem: "docker"
    directory: "/tests"
    schedule:
      interval: weekly
      day: monday
      time: "06:00"
    labels:
      - "dependencies"
      - "docker"

  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: weekly
      day: monday
      time: "06:00"
    labels:
      - "dependencies"
      - "python"
```

### Renovate Configuration

```json5
// renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:base",
    ":separateMajorMinor",
    ":combinePatchMinorUpdates",
    ":enableVulnerabilityAlerts"
  ],
  "labels": ["dependencies"],
  "schedule": ["before 6am on monday"],
  "packageRules": [
    {
      "description": "Group GitHub Actions updates",
      "matchManagers": ["github-actions"],
      "groupName": "GitHub Actions",
      "groupSlug": "github-actions"
    },
    {
      "description": "Group Docker updates",
      "matchManagers": ["dockerfile", "docker-compose"],
      "groupName": "Docker images",
      "groupSlug": "docker"
    },
    {
      "description": "Group pre-commit hooks",
      "matchManagers": ["pre-commit"],
      "groupName": "Pre-commit hooks",
      "groupSlug": "pre-commit"
    }
  ],
  "regexManagers": [
    {
      "description": "Update shellcheck version in CI configs",
      "fileMatch": ["\\.github/workflows/.+\\.yml$"],
      "matchStrings": ["shellcheck version: (?<currentValue>\\d+\\.\\d+)"],
      "datasourceTemplate": "github-releases",
      "depNameTemplate": "koalaman/shellcheck"
    }
  ]
}
```

[Check] Dependabot and Renovate configured for dependency updates

---

## 13. Combined CI Workflow (Recommended)

```yaml
# .github/workflows/ci-full.yml
name: Full CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  quality:
    name: Quality Gates
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: ShellCheck
        run: shellcheck -x $(find . -name '*.sh' -type f)
      - name: shfmt check
        run: shfmt -d -i 2 -ci -sr $(find . -name '*.sh' -type f)
      - name: Actionlint
        uses: reviewdog/action-actionlint@v1
        with:
          reporter: github-pr-review

  test:
    name: Tests (${{ matrix.os }})
    needs: quality
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v4
      - name: Install BATS
        run: |
          if [[ "$RUNNER_OS" == "macOS" ]]; then
            brew install bats-core
          else
            sudo apt-get update -qq
            sudo apt-get install -y -qq bats
          fi
      - name: Run tests
        run: bats tests/

  coverage:
    name: Coverage
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install kcov
        run: sudo apt-get install -y -qq kcov
      - name: Run with coverage
        run: |
          mkdir -p /tmp/coverage
          kcov --include-path=. --exclude-pattern=tests /tmp/coverage bats tests/
      - name: Upload artifact
        uses: actions/upload-artifact@v4
        with:
          name: coverage
          path: /tmp/coverage/

  security:
    name: Security
    runs-on: ubuntu-latest
    permissions:
      security-events: write
    steps:
      - uses: actions/checkout@v4
      - name: Initialize CodeQL
        uses: github/codeql-action/init@v3
        with:
          languages: actions
      - name: CodeQL analyze
        uses: github/codeql-action/analyze@v3
      - name: Secrets scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

---

## Section Reference for SKILL.md

The CI Integration section of SKILL.md routes to this file:

```markdown
### CI Integration
When setting up continuous integration for Bash projects, configuring automated checks, or standardizing pipelines:
1. Load `features/ci-integration.md` for GitHub Actions workflows, GitLab CI pipelines, pre-commit hooks, Makefile targets, matrix testing across shell dialects, containerized testing, actionlint, automated releases, coverage reporting, CodeQL scanning, secrets detection, and Dependabot/Renovate integration.
```

---

## Verification

[Check] CI/CD Integration feature file exists at features/ci-integration.md
[Check] GitHub Actions workflow includes shellcheck, shfmt, bats test matrix, multi-OS
[Check] GitLab CI covers shell lint stage, test stage, parallel execution
[Check] Pre-commit hooks configured with shellcheck, shfmt, checkbashisms
[Check] Makefile targets: lint, format, test, test-all, check (combines all)
[Check] Matrix testing across shells: bash 4.4, 5.0, 5.1, 5.2, dash, sh
[Check] Containerized testing uses Docker for reproducible bash versions
[Check] Actionlint validates GitHub Actions workflows
[Check] Automated releases support version tagging and changelog generation
[Check] Coverage reporting available for shell tests (kcov, shcov)
[Check] CodeQL scanning configured for shell scripts
[Check] Secrets detection covers gitleaks and trufflehog
[Check] Dependabot/Renovate configured for dependency updates
