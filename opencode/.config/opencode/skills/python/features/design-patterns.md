# Design Patterns

Directives for applying structural design principles in Python. Use these rules when designing a new component, refactoring tangled code, or deciding whether to introduce an abstraction.

## KISS and Separation of Concerns

Choose the simplest solution that works. Complexity must be justified by a concrete requirement, not by anticipation of hypothetical needs. Separate concerns into distinct layers so each layer has one job and a single reason to change.

- Prefer a plain function over a class when the code has no state.
- Prefer a dictionary or `match` statement over a factory/registry pattern when the dispatch table is small.
- Keep functions small (roughly 20-50 lines) and focused on one purpose.
- Enforce one-way dependency arrows between layers: API -> Service -> Repository. A lower layer importing from a higher layer is a violation.

```python
# Simple dispatch beats a framework when the table is small.
FORMATTERS = {"json": format_json, "csv": format_csv}


def format(name: str, data: dict) -> str:
    """Dispatch to the named formatter."""
    return FORMATTERS[name](data)
```

## Single Responsibility Principle

Each class and module should have one reason to change. Apply the "reason to change" test: list every change that could require editing the unit. If the list spans unrelated domains (HTTP parsing, business rules, formatting), split the unit. If every change stems from the same domain concern, the unit is appropriately sized.

- Split a class when its constructor grows past a handful of dependencies — that signals too many responsibilities, not a problem with dependency injection.
- Inject dependencies through the constructor so each layer is testable in isolation.
- Match file names to the single concept they hold (see `project-structure.md`).

```python
# SRP: one class, one reason to change.
class OrderProcessor:
    """Validates and transforms an order. Does not persist or render it."""

    def __init__(self, validator: OrderValidator) -> None:
        self._validator = validator

    def process(self, order: Order) -> ProcessedOrder:
        self._validator.validate(order)
        return ProcessedOrder.from_order(order)
```

## Composition Over Inheritance

Build behavior by composing objects, not by extending class hierarchies. Use inheritance only for genuine is-a relationships; use composition for code reuse. Deep inheritance trees couple unrelated classes and make behavior hard to reason about.

- Inject collaborators through the constructor and delegate to them.
- Define structural contracts with `Protocol` (see `type-safety.md`) rather than base classes when you need polymorphism without inheritance.
- Keep composition shallow (2-3 levels). Deeply nested wrappers are a sign that function composition or a Protocol-based approach would be clearer.

```python
# Composition: a notifier delegates to injected senders.
class Notifier:
    def __init__(self, senders: list[MessageSender]) -> None:
        self._senders = senders

    def notify(self, message: str) -> None:
        for sender in self._senders:
            sender.send(message)
```

## When to Abstract vs When to Duplicate

Apply the rule of three: wait until a pattern appears three times before extracting an abstraction. Premature abstraction couples otherwise-independent code and makes changes ripple. Duplication is often cheaper than the wrong abstraction.

- Extract on the third occurrence, not the first. Two similar blocks are not evidence of a pattern.
- Abstract immediately when duplicated copies are already diverging incorrectly — the rule of three is a heuristic, not a law.
- Delete dead code before abstracting; removing the cruft often reveals the real shape of the duplication.
- Prefer explicit over clever. Readable code beats elegant code that requires a comment to explain.

```python
# Rule of three: extract only when the third variant appears.
def render_json(data: dict) -> str: ...
def render_csv(data: dict) -> str: ...
# A third renderer (e.g., render_yaml) is the signal to extract a Renderer protocol.
```

## When to Use

- Designing a new service or component from scratch and choosing how to layer responsibilities.
- Refactoring a God class or monolithic function that has grown too large.
- Deciding whether to add a new abstraction or live with duplication.
- Choosing between inheritance and composition for a new class hierarchy.
- Evaluating a pull request for structural issues like tight coupling or leaking internal types.

## Cross-References

- See `anti-patterns.md` for the negative checklist that pairs with these positive patterns.
- See `project-structure.md` for module cohesion and directory layout that enforce these principles.
- See `type-safety.md` for `Protocol`-based structural typing as an alternative to inheritance.
- See `testing.md` for testing each layer in isolation using the dependency-injection structure established here.