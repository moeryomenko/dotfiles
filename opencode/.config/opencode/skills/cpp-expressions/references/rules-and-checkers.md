# Expressions and Statements (ES Section) - Rules and Checker Mapping

## ES.1 - ES.34: Declarations and Macros

| Rule | Guideline | Checker |
|------|-----------|---------|
| ES.1 | Prefer standard library | `readability-container-contains`, `readability-container-data-pointer`, `readability-container-size-empty`, `readability-string-compare`, `readability-use-anyofallof`, `readability-redundant-string-cstr`, `readability-redundant-string-init`, `modernize-use-starts-ends-with` |
| ES.2 | Prefer abstractions to language features | -- |
| ES.3 | Don't repeat yourself | `bugprone-branch-clone`, `bugprone-redundant-branch-condition`, `readability-redundant-control-flow`, `misc-redundant-expression`, `misc-unused-alias-decls` |
| ES.5 | Keep scopes small | -- |
| ES.6 | Declare in for-init/condition | -- |
| ES.7 | Short common names, long uncommon | -- |
| ES.8 | Avoid similar-looking names | `misc-confusable-identifiers`, `misc-misleading-identifier` |
| ES.9 | Avoid `ALL_CAPS` names | `bugprone-reserved-identifier` |
| ES.10 | One name per declaration | -- |
| ES.11 | `auto` to avoid repetition | `modernize-use-auto`, `modernize-use-structured-binding`, `readability-redundant-typename` |
| ES.12 | No name reuse in nested scopes | `readability-redundant-declaration` |
| ES.20 | Always initialize | `cppcoreguidelines-init-variables`, `cppcoreguidelines-pro-type-member-init` |
| ES.21 | Don't introduce variable early | -- |
| ES.22 | Don't declare without value | -- |
| ES.23 | Prefer `{}` initializer | `modernize-use-designated-initializers`, `modernize-return-braced-init-list` |
| ES.24 | `unique_ptr<T>` for pointers | `cppcoreguidelines-owning-memory` |
| ES.25 | `const`/`constexpr` unless modification needed | -- |
| ES.26 | No variable for two unrelated purposes | -- |
| ES.27 | `std::array`/`stack_array` for stack arrays | `modernize-avoid-c-arrays` |
| ES.28 | Lambdas for complex initialization | -- |
| ES.30 | No macros for text manipulation | `cppcoreguidelines-macro-usage` |
| ES.31 | No macros for constants/functions | `bugprone-macro-parentheses`, `bugprone-macro-repeated-side-effects` |
| ES.32 | `ALL_CAPS` for macro names | `cppcoreguidelines-macro-usage` |
| ES.33 | Unique macro names if needed | `cppcoreguidelines-macro-usage` |
| ES.34 | No C-style variadic functions | `cppcoreguidelines-pro-type-vararg`, `modernize-avoid-variadic-functions` |

## ES.40 - ES.79: Expressions and Control Flow

| Rule | Guideline | Checker |
|------|-----------|---------|
| ES.40 | Avoid complicated expressions | `bugprone-chained-comparison`, `bugprone-sizeof-container`, `bugprone-sizeof-expression`, `bugprone-suspicious-memory-comparison` |
| ES.41 | Parenthesize if in doubt | `readability-math-missing-parentheses`, `readability-redundant-parentheses` |
| ES.42 | Keep pointer use simple | `cppcoreguidelines-pro-bounds-pointer-arithmetic` |
| ES.43 | Avoid undefined order of evaluation | -- |
| ES.44 | Don't depend on arg evaluation order | -- |
| ES.45 | No magic constants | `readability-magic-numbers`, `readability-implicit-bool-conversion`, `readability-uppercase-literal-suffix`, `readability-use-std-min-max`, `modernize-use-bool-literals`, `modernize-use-std-numbers`, `modernize-raw-string-literal` |
| ES.46 | Avoid narrowing conversions | `bugprone-narrowing-conversions`, `performance-type-promotion-in-math-fn` |
| ES.47 | `nullptr` not `0`/`NULL` | `modernize-use-nullptr` |
| ES.48 | Avoid casts | `cppcoreguidelines-pro-type-cstyle-cast`, `cppcoreguidelines-pro-type-reinterpret-cast`, `modernize-avoid-c-style-cast`, `readability-redundant-casting` |
| ES.49 | Named casts if needed | `cppcoreguidelines-pro-type-cstyle-cast`, `modernize-avoid-c-style-cast` |
| ES.50 | Don't cast away `const` | `cppcoreguidelines-pro-type-const-cast` |
| ES.55 | Avoid range checking need | `cppcoreguidelines-pro-bounds-avoid-unchecked-container-access`, `cppcoreguidelines-pro-bounds-constant-array-index`, `bugprone-missing-end-comparison` |
| ES.56 | `std::move()` only when explicit move needed | -- |
| ES.60 | No `new`/`delete` outside RM functions | `cppcoreguidelines-owning-memory` |
| ES.61 | `delete[]` for arrays, `delete` for non-arrays | -- |
| ES.62 | Don't compare pointers into different arrays | -- |
| ES.63 | Don't slice | `cppcoreguidelines-slicing` |
| ES.64 | `T{e}` for construction | -- |
| ES.65 | Don't dereference invalid pointer | `bugprone-not-null-terminated-result`, `readability-delete-null-pointer` |
| ES.70 | `switch` over `if` for choice | -- |
| ES.71 | Range-`for` over `for` | `modernize-loop-convert`, `modernize-use-ranges` |
| ES.72 | `for` over `while` with loop var | `modernize-loop-convert` |
| ES.73 | `while` over `for` without loop var | -- |
| ES.74 | Loop var in for-init | -- |
| ES.75 | Avoid `do`-statements | `cppcoreguidelines-avoid-do-while` |
| ES.76 | Avoid `goto` | `cppcoreguidelines-avoid-goto` |
| ES.77 | Minimize `break`/`continue` | `bugprone-terminating-continue`, `readability-else-after-return` |
| ES.78 | No implicit fallthrough in `switch` | `bugprone-switch-missing-default-case` |
| ES.79 | `default` for common cases only | -- |

## ES.84 - ES.107: Statements and Arithmetic

| Rule | Guideline | Checker |
|------|-----------|---------|
| ES.84 | No unnamed local variable | `bugprone-standalone-empty` |
| ES.85 | Make empty statements visible | `bugprone-standalone-empty`, `bugprone-suspicious-semicolon`, `readability-braces-around-statements` |
| ES.86 | No loop var modification in body | -- |
| ES.87 | No redundant `==`/`!=` | `bugprone-assignment-in-if-condition` |
| ES.100 | Don't mix signed/unsigned | `modernize-use-integer-sign-comparison` |
| ES.101 | Unsigned for bit manipulation | `bugprone-signed-bitwise`, `bugprone-signed-char-misuse`, `modernize-use-std-bit` |
| ES.102 | Signed for arithmetic | -- |
| ES.103 | Don't overflow | -- |
| ES.104 | Don't underflow | -- |
| ES.105 | Don't divide by zero | -- |
| ES.106 | Don't avoid negatives with `unsigned` | -- |
| ES.107 | `gsl::index` for subscripts, not `unsigned` | -- |
