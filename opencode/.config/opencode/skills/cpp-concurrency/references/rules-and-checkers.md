# Concurrency (CP Section) - Rules and Checker Mapping

## CP.1 - CP.9: Fundamentals

| Rule | Guideline | Checker |
|------|-----------|---------|
| CP.1 | Assume multi-threaded context | `concurrency-mt-unsafe` |
| CP.2 | Avoid data races | `concurrency-mt-unsafe` |
| CP.3 | Minimize shared writable data | -- |
| CP.4 | Think in tasks, not threads | -- |
| CP.8 | Don't use `volatile` for sync | -- |
| CP.9 | Use tools to validate concurrent code | -- |

## CP.20 - CP.53: Locking and Threads

| Rule | Guideline | Checker |
|------|-----------|---------|
| CP.20 | RAII for locks, never plain lock/unlock | `modernize-use-scoped-lock` |
| CP.21 | `std::lock`/`scoped_lock` for multiple mutexes | -- |
| CP.22 | Don't call unknown code under lock | -- |
| CP.23 | Joining thread as scoped container | -- |
| CP.24 | Thread as global container | -- |
| CP.25 | Prefer `gsl::joining_thread` | -- |
| CP.26 | Don't `detach()` | `bugprone-bad-signal-to-kill-thread`, `concurrency-thread-canceltype-asynchronous` |
| CP.31 | Small data between threads: by value | -- |
| CP.32 | Shared ownership across threads: `shared_ptr` | -- |
| CP.40 | Minimize context switching | -- |
| CP.41 | Minimize thread creation/destruction | -- |
| CP.42 | Don't `wait` without condition | `bugprone-spuriously-wake-up-functions` |
| CP.43 | Minimize time in critical section | -- |
| CP.44 | Name lock guards | -- |
| CP.50 | Define mutex with guarded data | -- |
| CP.51 | No capturing lambdas as coroutines | `cppcoreguidelines-avoid-capturing-lambda-coroutines` |
| CP.52 | No locks across suspension points | `cppcoreguidelines-no-suspend-with-lock` |
| CP.53 | No reference params to coroutines | `cppcoreguidelines-avoid-reference-coroutine-parameters` |

## CP.60 - CP.201: Advanced

| Rule | Guideline | Checker |
|------|-----------|---------|
| CP.60 | `future` for concurrent return value | -- |
| CP.61 | `async()` for concurrent tasks | -- |
| CP.100 | Lock-free only when absolutely needed | -- |
| CP.101 | Distrust hardware/compiler | -- |
| CP.102 | Study literature | -- |
| CP.110 | No custom double-checked locking | -- |
| CP.111 | Conventional pattern for double-checked locking | -- |
| CP.200 | `volatile` only for non-C++ memory | -- |
| CP.201 | Signals | `bugprone-signal-handler` |
