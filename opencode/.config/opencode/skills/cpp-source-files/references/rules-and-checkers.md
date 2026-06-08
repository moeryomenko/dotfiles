# Source Files (SF Section) - Rules and Checker Mapping

| Rule | Guideline | Checker |
|------|-----------|---------|
| SF.1 | `.cpp` for code, `.h` for interfaces | -- |
| SF.2 | No object/non-inline function definitions in headers | `misc-definitions-in-headers` |
| SF.3 | Headers for multi-file declarations | `misc-include-cleaner` |
| SF.4 | Include headers before other declarations | `llvm-include-order` |
| SF.5 | `.cpp` includes its own header | -- |
| SF.6 | `using namespace` for transition/foundation/local only | `misc-unused-using-decls`, `misc-use-anonymous-namespace`, `misc-use-internal-linkage` |
| SF.7 | No `using namespace` at global scope in headers | `misc-anonymous-namespace-in-header` |
| SF.8 | `#include` guards for all headers | `readability-duplicate-include` |
| SF.9 | Avoid cyclic dependencies | `misc-header-include-cycle` |
| SF.10 | No implicit `#include` dependencies | -- |
| SF.11 | Headers self-contained | -- |
| SF.12 | `""` for local, `<>` for system | -- |
| SF.13 | Portable header identifiers | -- |
| SF.20 | Namespaces for logical structure | `modernize-concat-nested-namespaces`, `bugprone-std-namespace-modification` |
