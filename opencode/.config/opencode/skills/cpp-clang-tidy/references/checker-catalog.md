# Clang-Tidy Checker Catalog

Complete listing of clang-tidy checks organized by C++ Core Guidelines section. Each entry includes the check ID, whether it offers auto-fix, and the related guideline rule(s).

## cppcoreguidelines-* (Direct Guideline Enforcement)

| Check | Fix | Related Rule |
|-------|-----|-------------|
| `cppcoreguidelines-avoid-capturing-lambda-coroutines` | No | CP.51 |
| `cppcoreguidelines-avoid-const-or-ref-data-members` | No | C.12 |
| `cppcoreguidelines-avoid-do-while` | No | ES.75 |
| `cppcoreguidelines-avoid-goto` | No | ES.76 |
| `cppcoreguidelines-avoid-non-const-global-variables` | No | I.2, R.6 |
| `cppcoreguidelines-avoid-reference-coroutine-parameters` | No | CP.53 |
| `cppcoreguidelines-init-variables` | Yes | ES.20 |
| `cppcoreguidelines-interfaces-global-init` | No | I.22 |
| `cppcoreguidelines-macro-usage` | No | ES.30-33 |
| `cppcoreguidelines-misleading-capture-default-by-value` | Yes | F.54 |
| `cppcoreguidelines-missing-std-forward` | No | F.19 |
| `cppcoreguidelines-no-malloc` | No | R.10 |
| `cppcoreguidelines-no-suspend-with-lock` | No | CP.52 |
| `cppcoreguidelines-owning-memory` | No | R.20, R.3 |
| `cppcoreguidelines-prefer-member-initializer` | Yes | C.49 |
| `cppcoreguidelines-pro-bounds-array-to-pointer-decay` | No | I.13 |
| `cppcoreguidelines-pro-bounds-avoid-unchecked-container-access` | Yes | ES.55 |
| `cppcoreguidelines-pro-bounds-constant-array-index` | Yes | ES.55 |
| `cppcoreguidelines-pro-bounds-pointer-arithmetic` | No | ES.42 |
| `cppcoreguidelines-pro-type-const-cast` | No | ES.50 |
| `cppcoreguidelines-pro-type-cstyle-cast` | Yes | ES.48-49 |
| `cppcoreguidelines-pro-type-member-init` | Yes | ES.20 |
| `cppcoreguidelines-pro-type-reinterpret-cast` | No | ES.48 |
| `cppcoreguidelines-pro-type-static-cast-downcast` | Yes | C.153 |
| `cppcoreguidelines-pro-type-union-access` | No | C.183 |
| `cppcoreguidelines-pro-type-vararg` | No | F.55, ES.34 |
| `cppcoreguidelines-rvalue-reference-param-not-moved` | No | F.18 |
| `cppcoreguidelines-slicing` | No | ES.63 |
| `cppcoreguidelines-special-member-functions` | No | C.21 |
| `cppcoreguidelines-use-enum-class` | No | Enum.3 |
| `cppcoreguidelines-virtual-class-destructor` | Yes | C.35, C.127 |

## bugprone-* (Common Bugs)

| Check | Fix | Related Rule |
|-------|-----|-------------|
| `bugprone-assert-side-effect` | No | ES.40 |
| `bugprone-assignment-in-if-condition` | Yes | ES.87 |
| `bugprone-assignment-in-selection-statement` | No | ES.87 |
| `bugprone-bad-signal-to-kill-thread` | No | CP.26 |
| `bugprone-branch-clone` | No | ES.3 |
| `bugprone-chained-comparison` | No | ES.40 |
| `bugprone-copy-constructor-init` | Yes | C.49 |
| `bugprone-crtp-constructor-accessibility` | Yes | C.41 |
| `bugprone-dangling-handle` | No | R.1 |
| `bugprone-empty-catch` | No | E.17 |
| `bugprone-exception-escape` | No | E.16 |
| `bugprone-float-loop-counter` | No | ES.72 |
| `bugprone-forwarding-reference-overload` | No | F.19 |
| `bugprone-inaccurate-erase` | Yes | ES.40 |
| `bugprone-incorrect-enable-if` | Yes | T.48 |
| `bugprone-incorrect-enable-shared-from-this` | Yes | R.20 |
| `bugprone-infinite-loop` | No | ES.72 |
| `bugprone-macro-parentheses` | Yes | ES.31 |
| `bugprone-macro-repeated-side-effects` | No | ES.31 |
| `bugprone-misplaced-operator-in-strlen-in-alloc` | Yes | R.1 |
| `bugprone-misplaced-pointer-arithmetic-in-alloc` | Yes | R.1 |
| `bugprone-missing-end-comparison` | Yes | ES.55 |
| `bugprone-move-forwarding-reference` | Yes | F.19 |
| `bugprone-multiple-new-in-one-expression` | No | R.13 |
| `bugprone-narrowing-conversions` | No | ES.46 |
| `bugprone-no-escape` | No | E.16 |
| `bugprone-not-null-terminated-result` | Yes | ES.65 |
| `bugprone-parent-virtual-call` | Yes | C.128 |
| `bugprone-posix-return` | Yes | E.2 |
| `bugprone-random-generator-seed` | No | ES.45 |
| `bugprone-redundant-branch-condition` | Yes | ES.3 |
| `bugprone-reserved-identifier` | Yes | ES.9 |
| `bugprone-return-const-ref-from-parameter` | No | F.43 |
| `bugprone-shared-ptr-array-mismatch` | Yes | R.20 |
| `bugprone-sign-handler` | No | CP.201 |
| `bugprone-signed-bitwise` | No | ES.101 |
| `bugprone-signed-char-misuse` | No | ES.101 |
| `bugprone-sizeof-container` | No | ES.40 |
| `bugprone-sizeof-expression` | No | ES.40 |
| `bugprone-spuriously-wake-up-functions` | No | CP.42 |
| `bugprone-standalone-empty` | Yes | ES.85 |
| `bugprone-std-namespace-modification` | No | SF.20 |
| `bugprone-string-constructor` | Yes | ES.40 |
| `bugprone-string-integer-assignment` | Yes | ES.40 |
| `bugprone-suspicious-memset-usage` | Yes | C.180 |
| `bugprone-suspicious-missing-comma` | No | ES.40 |
| `bugprone-suspicious-semicolon` | Yes | ES.85 |
| `bugprone-suspicious-string-compare` | Yes | ES.40 |
| `bugprone-switch-missing-default-case` | No | ES.79 |
| `bugprone-terminating-continue` | Yes | ES.77 |
| `bugprone-throw-keyword-missing` | No | E.2 |
| `bugprone-throwing-static-initialization` | No | I.22 |
| `bugprone-unique-ptr-array-mismatch` | Yes | R.20 |
| `bugprone-unsafe-functions` | No | ES.40 |
| `bugprone-unused-local-non-trivial-variable` | No | R.1 |
| `bugprone-unused-raii` | Yes | R.1 |
| `bugprone-unused-return-value` | No | E.2 |
| `bugprone-use-after-move` | No | C.64 |

## modernize-* (C++ Modernization)

| Check | Fix | Related Rule |
|-------|-----|-------------|
| `modernize-avoid-bind` | Yes | F.11 |
| `modernize-avoid-c-arrays` | No | ES.27 |
| `modernize-avoid-c-style-cast` | Yes | ES.48-49 |
| `modernize-avoid-setjmp-longjmp` | No | E.2 |
| `modernize-avoid-variadic-functions` | No | F.55, ES.34 |
| `modernize-concat-nested-namespaces` | Yes | SF.20 |
| `modernize-deprecated-headers` | Yes | P.2 |
| `modernize-deprecated-ios-base-aliases` | Yes | P.2 |
| `modernize-loop-convert` | Yes | ES.71-72 |
| `modernize-macro-to-enum` | Yes | Enum.1 |
| `modernize-make-shared` | Yes | R.22 |
| `modernize-make-unique` | Yes | R.23 |
| `modernize-pass-by-value` | Yes | F.16 |
| `modernize-raw-string-literal` | Yes | ES.45 |
| `modernize-redundant-void-arg` | Yes | ES.40 |
| `modernize-replace-auto-ptr` | Yes | R.20 |
| `modernize-replace-disallow-copy-and-assign-macro` | Yes | C.81 |
| `modernize-replace-random-shuffle` | Yes | P.13 |
| `modernize-return-braced-init-list` | Yes | ES.23 |
| `modernize-shrink-to-fit` | Yes | Per.14 |
| `modernize-type-traits` | Yes | T.124 |
| `modernize-unary-static-assert` | Yes | T.150 |
| `modernize-use-auto` | Yes | ES.11 |
| `modernize-use-bool-literals` | Yes | ES.45 |
| `modernize-use-concepts` | Yes | T.10 |
| `modernize-use-constraints` | Yes | T.10 |
| `modernize-use-default-member-init` | Yes | C.48 |
| `modernize-use-designated-initializers` | Yes | ES.23 |
| `modernize-use-emplace` | Yes | Per.14 |
| `modernize-use-equals-default` | Yes | C.80 |
| `modernize-use-equals-delete` | Yes | C.81 |
| `modernize-use-integer-sign-comparison` | Yes | ES.100 |
| `modernize-use-nodiscard` | Yes | E.2 |
| `modernize-use-noexcept` | Yes | F.6, E.12 |
| `modernize-use-nullptr` | Yes | ES.47 |
| `modernize-use-override` | Yes | C.128 |
| `modernize-use-ranges` | Yes | ES.71 |
| `modernize-use-scoped-lock` | Yes | CP.20 |
| `modernize-use-starts-ends-with` | Yes | ES.1 |
| `modernize-use-std-bit` | Yes | ES.101 |
| `modernize-use-std-format` | Yes | P.13 |
| `modernize-use-std-numbers` | Yes | ES.45 |
| `modernize-use-std-print` | Yes | P.13 |
| `modernize-use-string-view` | Yes | F.7 |
| `modernize-use-structured-binding` | Yes | ES.11 |
| `modernize-use-trailing-return-type` | Yes | F.4 |
| `modernize-use-transparent-functors` | Yes | T.40 |
| `modernize-use-uncaught-exceptions` | Yes | E.16 |
| `modernize-use-using` | Yes | T.43 |

## performance-* (Performance)

| Check | Fix | Related Rule |
|-------|-----|-------------|
| `performance-avoid-endl` | Yes | Per.19 |
| `performance-enum-size` | No | Per.16 |
| `performance-for-range-copy` | Yes | Per.12 |
| `performance-implicit-conversion-in-loop` | No | Per.12 |
| `performance-inefficient-algorithm` | Yes | Per.7 |
| `performance-inefficient-string-concatenation` | No | Per.7 |
| `performance-inefficient-vector-operation` | Yes | Per.7 |
| `performance-move-const-arg` | Yes | F.18 |
| `performance-move-constructor-init` | No | C.66 |
| `performance-no-automatic-move` | No | C.66 |
| `performance-noexcept-destructor` | Yes | C.37 |
| `performance-noexcept-move-constructor` | Yes | C.66 |
| `performance-noexcept-swap` | Yes | C.85 |
| `performance-prefer-single-char-overloads` | Yes | Per.7 |
| `performance-string-view-conversions` | Yes | Per.7 |
| `performance-trivially-destructible` | Yes | Per.14 |
| `performance-type-promotion-in-math-fn` | Yes | ES.46 |
| `performance-unnecessary-copy-initialization` | Yes | Per.12 |
| `performance-unnecessary-value-param` | Yes | F.16 |
| `performance-use-std-move` | Yes | C.64 |

## readability-* (Readability)

| Check | Fix | Related Rule |
|-------|-----|-------------|
| `readability-avoid-const-params-in-decls` | Yes | F.7 |
| `readability-avoid-nested-conditional-operator` | No | ES.40 |
| `readability-braces-around-statements` | Yes | ES.85 |
| `readability-const-return-type` | Yes | F.49 |
| `readability-container-contains` | Yes | ES.1 |
| `readability-container-data-pointer` | Yes | ES.1 |
| `readability-container-size-empty` | Yes | ES.1 |
| `readability-convert-member-functions-to-static` | Yes | C.4 |
| `readability-delete-null-pointer` | Yes | ES.65 |
| `readability-duplicate-include` | Yes | SF.8 |
| `readability-else-after-return` | Yes | ES.77 |
| `readability-enum-initial-value` | Yes | Enum.8 |
| `readability-function-size` | No | F.3 |
| `readability-implicit-bool-conversion` | Yes | ES.45 |
| `readability-inconsistent-declaration-parameter-name` | Yes | F.9 |
| `readability-magic-numbers` | No | ES.45 |
| `readability-make-member-function-const` | Yes | Con.2 |
| `readability-math-missing-parentheses` | Yes | ES.41 |
| `readability-misleading-indentation` | No | ES.40 |
| `readability-non-const-parameter` | Yes | F.16 |
| `readability-redundant-access-specifiers` | Yes | C.8 |
| `readability-redundant-casting` | Yes | ES.48 |
| `readability-redundant-control-flow` | Yes | ES.3 |
| `readability-redundant-declaration` | Yes | ES.12 |
| `readability-redundant-inline-specifier` | Yes | F.5 |
| `readability-redundant-member-init` | Yes | C.49 |
| `readability-redundant-parentheses` | Yes | ES.41 |
| `readability-redundant-qualified-alias` | Yes | T.42 |
| `readability-redundant-smartptr-get` | Yes | R.20 |
| `readability-redundant-string-cstr` | Yes | ES.1 |
| `readability-redundant-string-init` | Yes | ES.1 |
| `readability-redundant-typename` | Yes | ES.11 |
| `readability-simplify-boolean-expr` | Yes | ES.40 |
| `readability-static-accessed-through-instance` | Yes | C.4 |
| `readability-string-compare` | Yes | ES.1 |
| `readability-trailing-comma` | Yes | ES.85 |
| `readability-uppercase-literal-suffix` | Yes | ES.45 |
| `readability-use-anyofallof` | No | ES.1 |
| `readability-use-std-min-max` | Yes | ES.45 |

## misc-* (Miscellaneous)

| Check | Fix | Related Rule |
|-------|-----|-------------|
| `misc-anonymous-namespace-in-header` | No | SF.6-7 |
| `misc-confusable-identifiers` | No | ES.8 |
| `misc-const-correctness` | Yes | Con.1-3 |
| `misc-definitions-in-headers` | Yes | SF.2 |
| `misc-explicit-constructor` | Yes | C.46 |
| `misc-header-include-cycle` | No | SF.9 |
| `misc-include-cleaner` | Yes | SF.3 |
| `misc-misleading-identifier` | No | ES.8 |
| `misc-misplaced-const` | No | Con.1 |
| `misc-multiple-inheritance` | No | C.135-136 |
| `misc-new-delete-overloads` | No | R.15 |
| `misc-non-copyable-objects` | No | C.11 |
| `misc-non-private-member-variables-in-classes` | No | C.8 |
| `misc-predictable-rand` | No | ES.45 |
| `misc-redundant-expression` | Yes | ES.3 |
| `misc-static-assert` | Yes | T.150 |
| `misc-static-initialization-cycle` | No | I.22 |
| `misc-throw-by-value-catch-by-reference` | No | E.15 |
| `misc-unconventional-assign-operator` | No | C.60 |
| `misc-uniqueptr-reset-release` | Yes | R.20 |
| `misc-unused-alias-decls` | Yes | ES.3 |
| `misc-unused-parameters` | Yes | F.9 |
| `misc-unused-using-decls` | Yes | SF.6 |
| `misc-use-anonymous-namespace` | No | SF.6 |
| `misc-use-internal-linkage` | Yes | SF.6 |

## concurrency-* (Concurrency)

| Check | Fix | Related Rule |
|-------|-----|-------------|
| `concurrency-mt-unsafe` | No | CP.1-2 |
| `concurrency-thread-canceltype-asynchronous` | No | CP.26 |

## cert-* (CERT Security)

| Check | Fix | Related Rule |
|-------|-----|-------------|
| `cert-dcl58-cpp` | No | R.15 |
| `cert-env33-c` | No | E.2 |
| `cert-err33-c` | No | E.2 |
| `cert-err34-c` | No | E.2 |
| `cert-err58-cpp` | No | I.22 |
| `cert-err60-cpp` | No | E.16 |
| `cert-err61-cpp` | No | E.15 |
| `cert-exp42-c` | No | ES.40 |
| `cert-flp37-c` | No | ES.40 |
| `cert-msc30-c` | No | ES.45 |
| `cert-msc32-c` | No | ES.45 |
| `cert-msc33-c` | No | ES.40 |
| `cert-msc50-cpp` | No | ES.45 |
| `cert-msc51-cpp` | No | ES.45 |
| `cert-msc54-cpp` | No | CP.201 |
| `cert-oop54-cpp` | No | C.62 |
| `cert-oop57-cpp` | No | C.180 |
| `cert-oop58-cpp` | No | C.61 |
| `cert-pos47-c` | No | CP.26 |
