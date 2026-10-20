---
name: domain-fintech
description: Use when building Rust financial systems involving money, currencies, ledgers, payments, trading, rounding, transactions, reconciliation, or audit records.
---

# Rust Financial-System Guidance

Financial rules are domain, jurisdiction, product, and persistence-model specific. Establish the currency model, allowed scales, rounding rules, overflow policy, transaction semantics, reconciliation requirements, retention policy, and regulatory controls before choosing a Rust type or crate.

## Monetary representation

Do not use binary floating point for monetary amounts unless the domain explicitly defines acceptable error bounds and rounding behavior. A suitable representation may be integer minor units, a fixed-scale integer, a decimal type, or another exact representation. Select it from the required range, scale, currencies, calculation rules, persistence format, and interoperability.

`rust_decimal::Decimal` can be a useful choice, but it is not a universal monetary representation. Ensure serialized/persisted values preserve the necessary scale and that every conversion has a documented rounding policy.

A monetary value usually needs currency metadata and checked arithmetic. Whether a negative result is valid is a domain rule, not a property of subtraction itself.

```rust
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Amount {
    minor_units: i64,
    currency: Currency,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Currency {
    Usd,
    Eur,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AmountError {
    CurrencyMismatch,
    Overflow,
}

impl Amount {
    pub fn checked_add(self, other: Self) -> Result<Self, AmountError> {
        if self.currency != other.currency {
            return Err(AmountError::CurrencyMismatch);
        }
        let minor_units = self.minor_units.checked_add(other.minor_units)
            .ok_or(AmountError::Overflow)?;
        Ok(Self { minor_units, currency: self.currency })
    }
}
```

## Ledger, consistency, and auditability

`Arc<T>` shares ownership; it neither makes records immutable nor creates an audit trail. An audit trail requires durable records with an appropriate append, authorization, integrity, retention, and reconciliation model. Structured logs can supplement that record but rarely substitute for it.

For balance-changing operations, specify atomicity and isolation at the persistence boundary. Use transaction mechanisms offered by the database or ledger rather than relying on in-process ownership alone. Model debits, credits, idempotency keys, state transitions, and externally visible outcomes according to the product's invariants.

## External boundaries

Validate untrusted messages, decimal strings, and currency codes before converting them into domain types. Carry enough context for reconciliation without leaking sensitive data to user-facing errors or logs. Define retry policy with idempotency, deadlines, cancellation, jitter, and settlement state in mind.

## Load next

- Numeric range, float policy, and overflow: `features/numeric.md`
- Domain types and invariants: `features/domain-modeling.md`, `features/type-safety.md`
- Error/retry boundaries: `features/error-handling.md`, `features/domain-error.md`
- Persistence and telemetry concerns: `features/lifecycle.md`, `features/observability.md`
