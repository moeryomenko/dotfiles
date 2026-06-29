# Domain Modeling (MEDIUM)

**Triggers**: domain model, DDD, domain-driven design, entity, value object, aggregate, repository, business rules, validation, invariant, newtype, primitive obsession.

## Core Question

**What is this concept's role in the domain?**

Before modeling in code:
- Is this an Entity (identity matters) or Value Object (interchangeable)?
- What invariants must be maintained at all times?
- Where are the aggregate boundaries?
- What ownership pattern fits the domain concept?

---

## Domain Concept Mapping

| Domain Concept | Rust Pattern | Ownership Implication |
|----------------|--------------|----------------------|
| Entity | struct + Id field | Owned, unique identity via `PartialEq` on ID |
| Value Object | struct + Clone/Copy | Shareable, immutable, equality by value |
| Aggregate Root | struct owns children | Clear ownership tree, invariants enforced at root |
| Repository | trait with async methods | Abstracts persistence, returns domain types |
| Domain Event | enum | Captures state changes, immutable |
| Domain Service | impl block or free fn | Stateless operations with domain logic |
| Specification | fn or Fn trait | Reusable predicate logic |

---

## Entity Pattern

### Identity-Based Equality

Entities have unique identity that persists across changes:

```rust
#[derive(Debug)]
pub struct UserId(Uuid);

#[derive(Debug)]
pub struct User {
    id: UserId,
    email: Email,
    name: String,
    status: UserStatus,
}

impl User {
    pub fn new(email: Email, name: String) -> Self {
        Self {
            id: UserId(Uuid::new_v4()),
            email,
            name,
            status: UserStatus::Active,
        }
    }

    pub fn deactivate(&mut self) {
        self.status = UserStatus::Inactive;
    }
}

impl PartialEq for User {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id  // Only compare identity
    }
}

impl Eq for User {}
```

### Enforcing Invariants in Entity Methods

```rust
impl Order {
    pub fn add_item(&mut self, item: OrderItem) -> Result<(), OrderError> {
        // Enforce aggregate invariants
        if self.status != OrderStatus::Pending {
            return Err(OrderError::NotModifiable);
        }
        if self.items.len() >= MAX_ITEMS {
            return Err(OrderError::ItemLimitExceeded);
        }
        self.items.push(item);
        self.total = self.calculate_total();
        Ok(())
    }

    pub fn submit(self) -> Result<SubmittedOrder, OrderError> {
        // Enforce submission invariants
        if self.items.is_empty() {
            return Err(OrderError::EmptyOrder);
        }
        Ok(SubmittedOrder {
            id: self.id,
            items: self.items,
            total: self.total,
            submitted_at: Utc::now(),
        })
    }
}
```

---

## Value Object Pattern

### Immutable, By-Value Equality

Value objects are interchangeable by their attributes:

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Email(String);

impl Email {
    pub fn new(s: String) -> Result<Self, ValidationError> {
        if !s.contains('@') || !s.contains('.') {
            return Err(ValidationError::InvalidEmail(s));
        }
        Ok(Self(s))
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl std::fmt::Display for Email {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}
```

### Composed Value Objects

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Money {
    pub amount: Decimal,
    pub currency: Currency,
}

impl Money {
    pub fn new(amount: Decimal, currency: Currency) -> Self {
        Self { amount, currency }
    }

    pub fn add(self, other: Money) -> Result<Self, CurrencyMismatch> {
        if self.currency != other.currency {
            return Err(CurrencyMismatch);
        }
        Ok(Self {
            amount: self.amount + other.amount,
            currency: self.currency,
        })
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Currency {
    Usd,
    Eur,
    Gbp,
}
```

---

## Aggregate Pattern

### Aggregate Root with Owned Children

The aggregate root is the single entry point for all mutations:

```rust
mod order {
    pub struct Order {
        id: OrderId,
        items: Vec<OrderItem>,
        total: Money,
        status: OrderStatus,
    }

    struct OrderItem {
        product_id: ProductId,
        quantity: NonZeroU32,
        price: Money,
    }

    impl Order {
        pub fn id(&self) -> &OrderId { &self.id }
        pub fn items(&self) -> &[OrderItem] { &self.items }
        pub fn total(&self) -> Money { self.total }
        pub fn status(&self) -> OrderStatus { self.status }
    }

    pub struct OrderId(Uuid);
    pub enum OrderStatus { Pending, Submitted, Shipped, Cancelled }
}
```

### Loading and Saving Aggregates

```rust
#[async_trait]
pub trait OrderRepository: Send + Sync {
    async fn find_by_id(&self, id: &OrderId) -> Result<Option<Order>, Error>;
    async fn save(&self, order: &Order) -> Result<(), Error>;
    async fn delete(&self, id: &OrderId) -> Result<(), Error>;
}
```

---

## Domain Service Pattern

Stateless operations that don't naturally belong to an entity:

```rust
pub struct PricingService {
    tax_calculator: Arc<dyn TaxCalculator>,
    discount_policy: Arc<dyn DiscountPolicy>,
}

impl PricingService {
    pub fn calculate_order_total(&self, items: &[OrderItem], customer: &Customer) -> Money {
        let subtotal = items.iter()
            .map(|i| i.price * i.quantity.get())
            .fold(Money::zero(), |a, b| a.add(b).unwrap());

        let discount = self.discount_policy.apply(subtotal, customer);
        let tax = self.tax_calculator.calculate(subtotal - discount, customer);

        subtotal - discount + tax
    }
}
```

---

## Common Mistakes

| Mistake | Why Wrong | Fix |
|---------|-----------|-----|
| Primitive obsession (String everywhere) | No type safety, validation gaps | Newtype wrappers with validation |
| Public fields with invariants | Invariants violated externally | Private fields + accessor methods |
| Leaked aggregate internals | Broken encapsulation | Methods on aggregate root only |
| Entity equality by all fields | Wrong semantics for mutable entities | By ID only |
| Value Object with identity | Confused semantics | No ID, equality by attributes |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| Anemic domain model (all getters/setters) | Procedural code disguised as OOP | Rich domain methods |
| Exposing internal collections as `&mut` | Aggregate invariants bypassed | Return immutable views or copies |
| Multiple aggregates in one module | Blurred boundaries | One module per aggregate |
| Repository per entity | Over-engineered | Repository per aggregate root |

---

## Cross-References

- For newtype patterns: load `type-safety`
- For API design with builders: load `api-design`
- For conversions between types: load `conversions`
- For validation at boundaries: load `patterns`
