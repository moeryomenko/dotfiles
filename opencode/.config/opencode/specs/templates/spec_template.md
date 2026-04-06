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

## 1. Context & Rationale
<!-- Describe the problem being solved and why this change is necessary. Reference existing code/files if applicable. -->

## 2. Objectives
<!-- High-level goals of this specification. What does success look like? -->
- [ ] Goal 1
- [ ] Goal 2

## 3. Technical Requirements
<!-- Detailed technical constraints. This is the CONTRACT for the @engineer. -->
### 3.1 API & Interface
- [ ] Requirement A (e.g., Function signature: `func Calculate(x int) int`)
- [ ] Requirement B

### 3.2 Data Structures & Models
- [ ] Requirement C

### 3.3 Constraints & Dependencies
- [ ] Constraint D (e.g., Must not use external libraries)
- [ ] Dependency E

## 4. Research Intelligence (Explorer Insights)
<!-- This section is populated by @explorer findings to provide high-fidelity context for the implementation plan. -->
### 4.1 Discovered Patterns & Idioms
- [ ] Pattern/Idiom 1

### 4.2 Identified Constraints & Dependencies
- [ ] Constraint/Dependency 1

### 4.3 Recommended Interface Signatures
- [ ] Signature 1

## 5. Implementation Plan
<!-- The step-by-step breakdown of tasks for the @plan agent to orchestrate. -->
1. [ ] Task 1
2. [ ] Task 2

## 6. Verification Contract (QA)
<!-- Detailed acceptance criteria for the @qa agent. This defines how the Spec will be proven correct. -->
### 6.1 Testability Audit (Pre-Implementation)
<!-- @qa must verify these requirements are testable before implementation begins. -->
- [ ] Requirement X is verifiable via [Unit/Integration] tests.
- [ ] Requirement Y has clear success/failure criteria.

### 6.2 Unit Test Scenarios
- [ ] Scenario 1: [Input] -> [Expected Output]
- [ ] Scenario 2: [Edge Case] -> [Expected Error/Behavior]

### 6.3 Integration/System Test Scenarios
- [ ] Scenario 3: [End-to-end flow]

## 7. Edge Cases & Risk Assessment
<!-- Known unknowns, potential failure modes, and boundary conditions to watch for. -->
- [ ] Risk X
- [ ] Boundary Condition Y

>>>>>>> 07e7771 (refactor(opencode): migrate from Go-specific tooling to SDD pipeline agents)
