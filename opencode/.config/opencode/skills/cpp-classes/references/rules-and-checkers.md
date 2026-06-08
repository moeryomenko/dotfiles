# Classes (C Section) - Rules and Checker Mapping

## C.1 - C.22: Class Design and Special Members

| Rule | Guideline | Checker |
|------|-----------|---------|
| C.1 | Organize related data into structs | -- |
| C.2 | `class` if invariant, `struct` if independent | -- |
| C.3 | Class for interface/implementation distinction | -- |
| C.4 | Member only if direct access to representation | `readability-convert-member-functions-to-static`, `readability-static-accessed-through-instance` |
| C.5 | Helper functions in same namespace | -- |
| C.7 | Don't define class and declare var in same statement | -- |
| C.8 | `class` if any member non-public | `readability-redundant-access-specifiers`, `misc-non-private-member-variables-in-classes` |
| C.9 | Minimize member exposure | -- |
| C.10 | Prefer concrete types over hierarchies | -- |
| C.11 | Make concrete types regular | `misc-non-copyable-objects` |
| C.12 | No `const`/ref data members in copyable/movable | `cppcoreguidelines-avoid-const-or-ref-data-members` |
| C.13 | Declare dependency order matches use order | -- |
| C.20 | Avoid defining default operations if possible | -- |
| C.21 | Define all or none of copy/move/destructor | `cppcoreguidelines-special-member-functions` |
| C.22 | Default operations consistent | -- |

## C.30 - C.52: Destructors and Constructors

| Rule | Guideline | Checker |
|------|-----------|---------|
| C.30 | Destructor if explicit action needed | -- |
| C.31 | All resources released by destructor | -- |
| C.32 | Raw pointer/ref: consider if owning | `cppcoreguidelines-owning-memory` |
| C.33 | Owning pointer member: define destructor | -- |
| C.35 | Base destructor: public+virtual or protected+non-virtual | `cppcoreguidelines-virtual-class-destructor` |
| C.36 | Destructor must not fail | -- |
| C.37 | Destructors `noexcept` | `performance-noexcept-destructor` |
| C.40 | Constructor if class has invariant | -- |
| C.41 | Constructor creates fully initialized object | `bugprone-crtp-constructor-accessibility` |
| C.42 | Throw if constructor cannot construct valid | -- |
| C.43 | Copyable class has default constructor | -- |
| C.44 | Default constructor: simple, non-throwing | -- |
| C.45 | Default member initializers over ctor-only init | -- |
| C.46 | Single-arg constructors: `explicit` by default | `misc-explicit-constructor` |
| C.47 | Init members in declaration order | `cppcoreguidelines-prefer-member-initializer`, `bugprone-copy-constructor-init` |
| C.48 | Default member initializers for constant values | `modernize-use-default-member-init` |
| C.49 | Initialization over assignment in constructors | `cppcoreguidelines-prefer-member-initializer` |
| C.50 | Factory for virtual behavior during init | -- |
| C.51 | Delegating constructors for common actions | -- |
| C.52 | Inheriting constructors for derived classes | -- |

## C.60 - C.90: Operations

| Rule | Guideline | Checker |
|------|-----------|---------|
| C.60 | Copy assignment: non-virtual, `const&` param, non-`const&` return | `misc-unconventional-assign-operator` |
| C.61 | Copy must copy | `cert-oop58-cpp` |
| C.62 | Copy assignment safe for self-assignment | `cert-oop54-cpp` |
| C.63 | Move assignment: non-virtual, `&&` param, non-`const&` return | -- |
| C.64 | Move must move, leave source valid | `performance-use-std-move`, `bugprone-use-after-move` |
| C.65 | Move assignment safe for self-assignment | -- |
| C.66 | Move operations `noexcept` | `performance-noexcept-move-constructor`, `performance-no-automatic-move` |
| C.67 | Polymorphic class: suppress public copy/move | -- |
| C.80 | `=default` for explicit default semantics | `modernize-use-equals-default` |
| C.81 | `=delete` to disable | `modernize-use-equals-delete` |
| C.82 | No virtual calls in ctors/dtors | -- |
| C.83 | `noexcept` swap for value-like types | -- |
| C.84 | Swap must not fail | -- |
| C.85 | Swap `noexcept` | `performance-noexcept-swap` |
| C.86 | `==` symmetric + `noexcept` | -- |
| C.87 | `==` on base classes | -- |
| C.89 | Hash `noexcept` | -- |
| C.90 | Constructors/assignment over `memset`/`memcpy` | `bugprone-suspicious-memset-usage` |

## C.120 - C.183: Hierarchies and Advanced

| Rule | Guideline | Checker |
|------|-----------|---------|
| C.120 | Hierarchies for inherent hierarchical structure | -- |
| C.121 | Interface base: pure abstract | -- |
| C.122 | Abstract for interface/implementation separation | -- |
| C.126 | Abstract class: no user-written constructor | -- |
| C.127 | Virtual function needs virtual/protected destructor | `cppcoreguidelines-virtual-class-destructor` |
| C.128 | Virtual/override/final exactly one | `modernize-use-override`, `bugprone-parent-virtual-call` |
| C.129 | Distinguish implementation vs interface inheritance | -- |
| C.130 | Virtual `clone` for deep copy | -- |
| C.131 | Avoid trivial getters/setters | -- |
| C.132 | Virtual only with reason | -- |
| C.133 | Avoid `protected` data | -- |
| C.134 | Same access level for all non-const data | -- |
| C.135 | MI for distinct interfaces | `misc-multiple-inheritance` |
| C.136 | MI for implementation union | -- |
| C.137 | Virtual bases for overly general bases | -- |
| C.138 | `using` for overload sets | -- |
| C.139 | `final` sparingly | -- |
| C.140 | No different defaults for virtual/overrider | -- |
| C.145 | Access polymorphic through pointers/references | `cppcoreguidelines-slicing` |
| C.146 | `dynamic_cast` where hierarchy navigation needed | -- |
| C.147 | `dynamic_cast` to ref when failure is error | -- |
| C.148 | `dynamic_cast` to ptr when failure is alternative | -- |
| C.149 | `unique_ptr`/`shared_ptr` to avoid forgetting `delete` | -- |
| C.150 | `make_unique` for `unique_ptr` | `modernize-make-unique` |
| C.151 | `make_shared` for `shared_ptr` | `modernize-make-shared` |
| C.152 | No array of derived to base pointer | -- |
| C.153 | Prefer virtual to casting | `cppcoreguidelines-pro-type-static-cast-downcast` |
| C.160 | Operators mimic conventional usage | -- |
| C.161 | Symmetric operators: non-member | -- |
| C.162 | Overload roughly equivalent operations | -- |
| C.163 | Overload only roughly equivalent | -- |
| C.164 | Avoid implicit conversion operators | -- |
| C.165 | `using` for customization points | -- |
| C.166 | Unary `&` only for smart pointers | -- |
| C.167 | Operator for conventional meaning | -- |
| C.168 | Operators in operand namespace | -- |
| C.170 | Generic lambda for lambda overload | -- |
| C.180 | `union` for memory savings | `cert-oop57-cpp` |
| C.181 | Avoid naked `union` | -- |
| C.182 | Anonymous `union` for tagged unions | -- |
| C.183 | No `union` for type punning | `cppcoreguidelines-pro-type-union-access` |
