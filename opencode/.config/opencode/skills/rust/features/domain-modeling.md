# Domain Modeling

Model distinctions and invariants that matter to the target domain; do not impose domain-driven-design terminology where a simpler data model is clearer. Establish identity, validation rules, mutation authority, persistence boundaries, and consistency requirements before choosing Rust types.

## Entities and value types

An entity has identity whose meaning survives changes to its other fields. A value type is compared by the attributes the domain declares meaningful. Use newtypes or enums when they prevent a real category error or centralize validation; use primitives when the distinction would add no useful contract.

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub struct AccountId(u64);

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Email(String);

impl Email {
    pub fn parse(value: String) -> Result<Self, EmailError> {
        if !value.contains('@') { return Err(EmailError::Invalid); }
        Ok(Self(value))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum EmailError { Invalid }
```

Derive `Copy` only when implicit duplication is inexpensive and semantically right; derive `Clone`, equality, ordering, or hashing only when those operations express the domain contract.

## Invariants and ownership

Keep fields private when exposing mutation would bypass an invariant. An aggregate boundary may be useful when several values must change atomically, but it need not correspond to one module, one repository, or a particular ownership tree. Put validation where it can be enforced reliably: parsing boundaries, constructors, transition methods, or persistence transactions as appropriate.

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Currency { Usd, Eur }

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Money {
    minor_units: i64,
    currency: Currency,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MoneyError { CurrencyMismatch, Overflow }

impl Money {
    pub fn checked_add(self, other: Self) -> Result<Self, MoneyError> {
        if self.currency != other.currency {
            return Err(MoneyError::CurrencyMismatch);
        }
        let minor_units = self.minor_units.checked_add(other.minor_units)
            .ok_or(MoneyError::Overflow)?;
        Ok(Self { minor_units, currency: self.currency })
    }
}
```

Choose repository traits, domain services, events, and async abstraction only where a real boundary or variability requirement exists. Their public signatures must specify error, cancellation, transaction, and consistency behavior.

## Load next

- Newtypes and representation: `type-safety.md`
- Financial precision and persistence: `../domain-fintech/SKILL.md`
- Public contracts: `api-design.md`
- Error and transaction boundaries: `domain-error.md`, `lifecycle.md`
