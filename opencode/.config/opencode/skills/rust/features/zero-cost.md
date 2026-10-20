# Dispatch and Abstraction Cost

Choose an abstraction for the required extensibility, ownership, compile time, binary size, and measured runtime behavior. "Zero cost" means a suitable abstraction need not impose unavoidable overhead; it is not a guarantee that every generic, iterator, enum, or inline annotation optimizes identically.

## Dispatch choices

| Need | Usual option | Tradeoff |
|---|---|---|
| Caller knows one concrete type | generic parameter or argument-position `impl Trait` | monomorphization can increase compile time and code size |
| Hide one concrete return type | return-position `impl Trait` | each function path must resolve to one hidden concrete type |
| Open set or heterogeneous values | `dyn Trait` | indirect call and, for `Box`, allocation/indirection |
| Closed, known alternatives | enum | runtime `match` branch unless optimized away; API grows with variants |

Static dispatch can enable optimization and inlining, but neither is guaranteed. Dynamic dispatch can reduce duplication or simplify a stable boundary. Measure a hot path before privileging one option for performance.

```rust
trait Processor {
    fn process(&self, input: &str) -> String;
}

fn run_static<P: Processor>(processor: &P, input: &str) -> String {
    processor.process(input)
}

fn run_dynamic(processor: &dyn Processor, input: &str) -> String {
    processor.process(input)
}
```

Trait objects require a dyn-compatible trait. For owned trait objects use `Box<dyn Trait>` (not `Box<dyn Trait>` as a substitute for a known concrete type); other owners such as `Arc<dyn Trait + Send + Sync>` can fit different sharing constraints.

## `impl Trait`

Argument-position `impl Trait` is syntactic sugar for a generic parameter. Return-position `impl Trait` names one opaque concrete type selected by the implementation. Return different concrete iterator types only by unifying them (for example, with an enum) or selecting a dynamic/boxing design deliberately.

## Load next

- Dyn compatibility rules: `traits.md`
- Closure representation: `closures.md`
- Profiling and optimizer decisions: `performance.md`, `optimization.md`
