# Error Handling (E Section) - Rules and Checker Mapping

| Rule | Guideline | Checker |
|------|-----------|---------|
| E.1 | Develop error strategy early | -- |
| E.2 | Throw when function can't perform task | `bugprone-throw-keyword-missing`, `bugprone-posix-return`, `modernize-use-nodiscard`, `modernize-avoid-setjmp-longjmp` |
| E.3 | Exceptions for errors only | -- |
| E.4 | Design error strategy around invariants | -- |
| E.5 | Constructor establishes invariant, throw if not | -- |
| E.6 | RAII to prevent leaks | `bugprone-unused-raii` |
| E.7 | State preconditions | -- |
| E.8 | State postconditions | -- |
| E.12 | `noexcept` when throw impossible/unacceptable | `modernize-use-noexcept` |
| E.13 | Never throw while owning object | -- |
| E.14 | UDTs as exceptions, not built-ins | -- |
| E.15 | Throw by value, catch by reference | `misc-throw-by-value-catch-by-reference`, `cert-err61-cpp` |
| E.16 | Destructors/dealloc/swap/exception copy must not fail | `bugprone-exception-escape`, `bugprone-no-escape`, `performance-noexcept-destructor`, `performance-noexcept-move-constructor`, `modernize-use-uncaught-exceptions`, `cert-err60-cpp` |
| E.17 | Don't catch every exception everywhere | `bugprone-empty-catch` |
| E.18 | Minimize explicit try/catch | -- |
| E.19 | `final_action` for cleanup without suitable handle | -- |
| E.25 | Simulate RAII without exceptions | -- |
| E.26 | Fail fast without exceptions | -- |
| E.27 | Error codes without exceptions | -- |
| E.28 | No global state error handling (errno) | -- |
| E.30 | No exception specifications | -- |
| E.31 | Order catch clauses: derived first | -- |
