# Performance (Per Section) - Rules and Checker Mapping

| Rule | Guideline | Checker |
|------|-----------|---------|
| Per.1 | Don't optimize without reason | -- |
| Per.2 | Don't optimize prematurely | -- |
| Per.3 | Don't optimize non-critical | -- |
| Per.4 | Complex != fast | -- |
| Per.5 | Low-level != fast | -- |
| Per.6 | Measure, don't guess | -- |
| Per.7 | Design to enable optimization | `performance-inefficient-algorithm`, `performance-inefficient-string-concatenation`, `performance-inefficient-vector-operation`, `performance-prefer-single-char-overloads`, `performance-string-view-conversions` |
| Per.10 | Rely on static type system | -- |
| Per.11 | Move computation to compile time | -- |
| Per.12 | Eliminate redundant aliases | `performance-unnecessary-copy-initialization`, `performance-for-range-copy`, `performance-implicit-conversion-in-loop` |
| Per.13 | Eliminate redundant indirection | -- |
| Per.14 | Minimize allocations/deallocations | `performance-trivially-destructible`, `modernize-shrink-to-fit`, `modernize-use-emplace` |
| Per.15 | No allocation on critical path | -- |
| Per.16 | Compact data structures | `performance-enum-size` |
| Per.17 | Most-used member first | -- |
| Per.18 | Space is time | -- |
| Per.19 | Access memory predictably | `performance-avoid-endl` |
| Per.30 | Avoid context switches on critical path | -- |

## Move and Noexcept Performance

| Checker | Purpose |
|---------|---------|
| `performance-move-const-arg` | Moving from const arg is copy |
| `performance-move-constructor-init` | Use move in member init |
| `performance-no-automatic-move` | Has noexcept copy, no move |
| `performance-noexcept-move-constructor` | Move constructor should be noexcept |
| `performance-noexcept-destructor` | Destructor should be noexcept |
| `performance-noexcept-swap` | Swap should be noexcept |
| `performance-use-std-move` | Use std::move instead of copy |
| `performance-unnecessary-value-param` | Pass by reference instead |
