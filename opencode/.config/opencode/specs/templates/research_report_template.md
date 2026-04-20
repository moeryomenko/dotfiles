# Research Report: [Topic/Module Under Investigation]

> **Researcher**: @explorer
> **Date**: [YYYY-MM-DD]
> **Requested By**: @plan or @build
> **Related Spec**: [SPEC-XXX if applicable]

---

## 1. Research Objective

[What question(s) is this research trying to answer? Be specific.]

---

## 2. Findings

### 2.1 Codebase Structure
[How is the relevant code organized? Include directory/file structure if helpful.]

| File | Purpose | Key Types/Functions |
|------|---------|-------------------|
| `path/to/file.go` | [What this file does] | `TypeA`, `FunctionB()` |

### 2.2 Key Mechanisms
[Describe how the relevant code works. Include data flows, call chains, and state management.]

#### 2.2.1 [Sub-topic 1]
- [Finding with specific file:line references]
- [Evidence from code]

#### 2.2.2 [Sub-topic 2]
- [Finding with specific file:line references]
- [Evidence from code]

### 2.3 Existing Patterns & Idioms
[What patterns does the codebase use? This helps @engineer write consistent code.]

| Pattern | Where Used | How It Works |
|---------|-----------|--------------|
| [e.g., Functional options] | `config/*.go` | [Brief description] |

### 2.4 Dependencies & External APIs
- [External libraries used and versions]
- [Internal package dependencies]
- [API contracts with other services]

---

## 3. Constraints & Risks

### 3.1 Technical Constraints
- [Hard constraints that any implementation must respect]
- [e.g., "Cannot modify `pkg/internal/` — it is managed by another team"]

### 3.2 Hidden Risks
- [Edge cases or gotchas discovered during research]
- [Performance implications of existing patterns]
- [Concurrency hazards in shared code]

### 3.3 Breaking Change Assessment
| Change | Breaking? | Migration Path |
|--------|-----------|---------------|
| [Change description] | Yes/No | [How to handle] |

---

## 4. Recommendations for @build / @engineer

### 4.1 Implementation Guidance
- [Specific advice for implementing the feature]
- [Recommended approach vs. alternatives considered]
- [File paths and line numbers that are most relevant]

### 4.2 Files to Read (Priority Order)
1. `path/to/critical/file.go:45` — [Why this file is critical]
2. `path/to/related/file.go:120` — [What to learn from this file]

### 4.3 What to Avoid
- [Specific patterns or approaches that should not be used]
- [Files or packages that are off-limits]

---

## 5. Evidence Appendix

### 5.1 Code Snippets
```go
// Most relevant code snippet with explanation
func CriticalFunction() {
    // ... (from pkg/module/file.go:42-89)
}
```

### 5.2 References
- [External documentation links]
- [RFCs or design docs]
- [Related issues or PRs]
