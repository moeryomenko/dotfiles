# Templates (T Section) - Rules and Checker Mapping

| Rule | Guideline | Checker |
|------|-----------|---------|
| T.1 | Templates to raise abstraction level | -- |
| T.2 | Templates for algorithms over many types | -- |
| T.3 | Templates for containers and ranges | -- |
| T.4 | Templates for syntax tree manipulation | -- |
| T.5 | Combine generic and OO techniques | -- |
| T.10 | Concepts for all template args | `modernize-use-concepts`, `modernize-use-constraints` |
| T.11 | Standard concepts when possible | -- |
| T.12 | Concept names over `auto` | -- |
| T.13 | Shorthand for simple single-type concepts | -- |
| T.20 | No concepts without meaningful semantics | -- |
| T.21 | Complete operations for concept | -- |
| T.22 | Axioms for concepts | -- |
| T.23 | Refined concept adds new use patterns | -- |
| T.24 | Tag classes/traits for semantic differentiation | -- |
| T.25 | Avoid complementary constraints | -- |
| T.26 | Concepts in terms of use-patterns | -- |
| T.40 | Function objects for algorithm operations | `modernize-use-transparent-functors` |
| T.41 | Essential properties only in concepts | -- |
| T.42 | Template aliases to simplify notation | `readability-redundant-qualified-alias` |
| T.43 | `using` over `typedef` | `modernize-use-using` |
| T.44 | Function templates for CTAD | -- |
| T.47 | Avoid unconstrained templates with common names | -- |
| T.48 | `enable_if` to fake concepts | `bugprone-incorrect-enable-if` |
| T.49 | Avoid type-erasure | -- |
| T.60 | Minimize template context dependencies | -- |
| T.61 | Don't over-parameterize members (SCARY) | -- |
| T.62 | Non-dependent members in non-templated base | -- |
| T.64 | Specialization for alt implementations | -- |
| T.65 | Tag dispatch for function alternatives | -- |
| T.67 | Specialization for irregular types | -- |
| T.68 | `{}` not `()` in templates | -- |
| T.69 | Unqualified calls = customization points | -- |
| T.80 | Don't naively templatize hierarchy | -- |
| T.81 | Don't mix hierarchies and arrays | -- |
| T.82 | Linearize hierarchy without virtual | -- |
| T.83 | No member function template virtual | -- |
| T.84 | Non-template core for ABI stability | -- |
| T.100 | Variadic templates for variable args | -- |
| T.102 | Process variadic template args | -- |
| T.103 | No variadic for homogeneous args | -- |
| T.120 | TMP only when really needed | -- |
| T.121 | TMP primarily to emulate concepts | -- |
| T.122 | Templates for compile-time types | -- |
| T.123 | `constexpr` for compile-time values | -- |
| T.124 | Standard-library TMP facilities | `modernize-type-traits` |
| T.125 | Existing library beyond standard-library TMP | -- |
| T.140 | Name reusable operations | -- |
| T.141 | Unnamed lambda for one-use | -- |
| T.143 | No unintentionally non-generic code | -- |
| T.144 | Don't specialize function templates | -- |
| T.150 | `static_assert` for concept matching | `modernize-unary-static-assert`, `misc-static-assert` |
