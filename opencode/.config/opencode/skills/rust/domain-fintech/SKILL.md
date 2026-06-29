---
name: domain-fintech
description: Use when building fintech applications in Rust. Keywords: fintech, trading, decimal, currency, financial, money, transaction, ledger, payment, exchange rate, precision, rounding, accounting, audit.
---

# Domain: FinTech (Rust)

**Triggers**: fintech, trading, decimal, currency, financial, money, transaction, ledger, payment, exchange rate, precision, rounding, accounting, audit, compliance.

## Domain Constraints -> Design Implications

| Domain Rule | Design Constraint | Rust Implication |
|-------------|-------------------|------------------|
| Audit trail | Immutable records | Arc<T>, no mutation |
| Precision | No floating point | rust_decimal::Decimal |
| Consistency | Transaction boundaries | Clear ownership |
| Compliance | Complete logging | Structured tracing |
| Reproducibility | Deterministic execution | No race conditions |

---

## Critical Constraints

### Financial Precision

```
RULE: Never use f64 for money
WHY: Floating point loses precision with cents
RUST: Use rust_decimal::Decimal for all monetary values
```

### Audit Requirements

```
RULE: All transactions must be immutable and traceable
WHY: Regulatory compliance, dispute resolution
RUST: Arc<T> for sharing, event sourcing pattern
```

### Consistency

```
RULE: Money can't disappear or appear
WHY: Double-entry accounting principles
RUST: Transaction types with validated totals
```

---

## Key Crates

| Purpose | Crate |
|---------|-------|
| Decimal math | rust_decimal |
| Date/time | chrono, time |
| UUID | uuid |
| Serialization | serde |
| Validation | validator |

## Design Patterns

| Pattern | Purpose | Implementation |
|---------|---------|----------------|
| Currency newtype | Type safety | `struct Amount(Decimal);` |
| Transaction | Atomic operations | Event sourcing |
| Audit log | Traceability | Structured logging with trace IDs |
| Ledger | Double-entry | Debit/credit balance |

## Code Pattern: Currency Type

```rust
use rust_decimal::Decimal;

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Amount {
    value: Decimal,
    currency: Currency,
}

impl Amount {
    pub fn new(value: Decimal, currency: Currency) -> Self {
        Self { value, currency }
    }

    pub fn add(&self, other: &Amount) -> Result<Amount, CurrencyMismatch> {
        if self.currency != other.currency {
            return Err(CurrencyMismatch);
        }
        Ok(Amount::new(self.value + other.value, self.currency))
    }

    /// Checked subtraction — returns None if result would be negative
    pub fn sub(&self, other: &Amount) -> Result<Amount, CurrencyMismatch> {
        if self.currency != other.currency {
            return Err(CurrencyMismatch);
        }
        if self.value < other.value {
            return Err(InsufficientFunds);
        }
        Ok(Amount::new(self.value - other.value, self.currency))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Currency { Usd, Eur, Gbp, Jpy, Cny }
```

---

## Common Mistakes

| Mistake | Domain Violation | Fix |
|---------|-----------------|-----|
| Using f64 | Precision loss | rust_decimal |
| Mutable transaction | Audit trail broken | Immutable + events |
| String for amount | No validation | Validated newtype |
| Silent overflow | Money disappears | Checked arithmetic |

## Layer Mapping

| Constraint | Feature File |
|------------|--------------|
| Immutable records | load `features/domain-modeling.md` |
| Type safety | load `features/type-safety.md` |
| Precision numbers | load `features/numeric.md` |
| Structured logging | load `features/observability.md` |
