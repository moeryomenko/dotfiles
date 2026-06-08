<<<<<<< HEAD
<<<<<<< HEAD
# Spec: [Feature Name]

- Status: DRAFT | APPROVED
- Author: [Name]
- Date: [YYYY-MM-DD]
- Spec ID: [feature-name]

## 1. Overview

[2-3 paragraphs describing the feature at a high level. What problem does it solve? Who is it for?]

## 2. Context

[Technical context: existing architecture, related components, dependencies.]

## 3. Technical Requirements

### REQ-001: [Requirement Title]
[Detailed description of the requirement]

### REQ-002: [Requirement Title]
[Detailed description]

[... more requirements as needed]

## 4. Verification Contract

### VC-01: [Verification Criterion Title]
- **Condition**: [Testable pass/fail condition]
- **Type**: [UNIT | INTEGRATION | E2E | MANUAL]

### VC-02: [Verification Criterion Title]
- **Condition**: [Testable pass/fail condition]
- **Type**: [UNIT | INTEGRATION | E2E | MANUAL]

[... at least 5 VCs]

### VC-N: [Verification Criterion Title]
- **Condition**: [Testable pass/fail condition]
- **Type**: [UNIT | INTEGRATION | E2E | MANUAL]

## 5. Non-Objectives

- [What is explicitly NOT in scope]
- [Future concerns, not part of this spec]

## 6. Risks and Unknowns

- [Technical risks]
- [Dependency risks]
- [Unknowns that need exploration]

## 7. Research Findings

[Filled in by @explorer. Links to research_report.md if applicable.]
=======
# Specification: [Feature Name]
=======
# Specification: [Feature/Task Name]
>>>>>>> a13d2dc (feat(opencode): add development agents and refine multi-agent workflow)

> **Status**: `DRAFT` → `APPROVED` → `IMPLEMENTED` → `VERIFIED`
> **Author**: @plan (Spec Architect)
> **Date**: [YYYY-MM-DD]
> **Spec ID**: [e.g., SPEC-001]

---

## 1. Overview

### 1.1 Problem Statement
[What problem are we solving? Be specific and concise.]

### 1.2 Objectives
- [Objective 1: measurable outcome]
- [Objective 2: measurable outcome]
- [Objective 3: measurable outcome]

### 1.3 Non-Objectives
- [What is explicitly OUT of scope — critical for preventing scope creep]
- [What will NOT be changed]

---

## 2. User/Technical Context

### 2.1 Affected Components
| Component | File(s) | Current Behavior | Required Change |
|-----------|---------|-----------------|-----------------|
| [Component name] | `path/to/file.go` | [Current behavior] | [What needs to change] |

### 2.2 Dependencies
- [External libraries or modules this depends on]
- [Internal packages that must not be broken]

### 2.3 Constraints
- [Performance requirements, e.g., "must handle 10K req/s"]
- [Compatibility requirements, e.g., "must support Go 1.21+"]
- [Security requirements, e.g., "no plaintext secrets in memory"]
- [API compatibility, e.g., "existing API must remain backward compatible"]

---

## 3. Technical Requirements

### 3.1 Interface/Type Contracts
```go
// Required new types/functions with exact signatures (language-agnostic — adapt to project language)
type NewInterface interface {
    Method(input string) (Result, error)
}

func NewFunction(ctx context.Context, config Config) (*NewType, error)
```

### 3.2 Data Flow
[Describe how data moves through the system. Include diagrams if complex.]

### 3.3 Error Handling Strategy
- [Specific error types that must be defined]
- [Error wrapping requirements: use `%w` for all wrapped errors]
- [Recovery behavior for recoverable errors]

### 3.4 Configuration
- [New config options required]
- [Environment variables or file paths]

---

## 4. Verification Contract (Acceptance Criteria)

Each criterion below MUST be met for the spec to be considered complete.

| ID | Criterion | Testable? | Priority |
|----|-----------|-----------|----------|
| VC-01 | [Specific, measurable condition] | Yes/No | P0/P1/P2 |
| VC-02 | [Specific, measurable condition] | Yes/No | P0/P1/P2 |
| VC-03 | [Specific, measurable condition] | Yes/No | P0/P1/P2 |

### 4.1 Edge Cases to Verify
- [Edge case 1: e.g., "Empty input slice must return nil, not error"]
- [Edge case 2: e.g., "Concurrent calls to same instance must not share state"]
- [Edge case 3: e.g., "Context cancellation during long operation must clean up resources"]

<<<<<<< HEAD
>>>>>>> 07e7771 (refactor(opencode): migrate from Go-specific tooling to SDD pipeline agents)
=======
### 4.2 Performance Benchmarks (if applicable)
- [Metric]: [Target value] — [Measurement method]

---

## 5. Implementation Tasks (To be assigned by @build)

> @build will decompose the requirements above into atomic tasks and assign them to @engineer.

| Task ID | Description | Assigned Agent | Dependencies |
|---------|-------------|---------------|--------------|
| TASK-01 | [Atomic task description] | @engineer / self | — |
| TASK-02 | [Atomic task description] | @engineer | TASK-01 |

---

## 6. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| [Risk description] | High/Med/Low | High/Med/Low | [How to mitigate] |

---

## 7. Appendices

### 7.1 Research Findings
[From @explorer — include key findings, file paths, and code references]

### 7.2 Related Specs
- [Link to related or blocking specs]

### 7.3 Changelog
| Date | Version | Change |
|------|---------|--------|
| [YYYY-MM-DD] | v0.1 (DRAFT) | Initial draft |
>>>>>>> a13d2dc (feat(opencode): add development agents and refine multi-agent workflow)
