---
name: cpp-concurrency
description: C++ Core Guidelines CP section: Concurrency and parallelism. Use when writing multi-threaded code, managing locks/mutexes, using atomics, coroutines, or configuring clang-tidy for concurrency rules.
---

# C++ Concurrency (CP Section)

Guidelines for multi-threaded programming, locks, atomics, and coroutines.

## Fundamental Principles

- **Assume multi-threaded** (CP.1): all code runs in a concurrent context
- **Avoid data races** (CP.2)
- **Minimize shared writable data** (CP.3)
- **Think in tasks, not threads** (CP.4)
- **Don't use `volatile` for sync** (CP.8)

## Locking (RAII Only)

- **Use RAII for locks, never plain `lock()`/`unlock()`** (CP.20)
- **Multiple mutexes: `std::lock` or `scoped_lock`** (CP.21)
- **Don't call unknown code under lock** (CP.22)
- **Name your lock guards** (CP.44)

```cpp
// BAD: manual lock/unlock
mutex m;
m.lock();
do_work();
m.unlock();  // skipped on exception

// GOOD: RAII lock
mutex m;
{
    lock_guard<mutex> lk{m};
    do_work();  // unlocked on scope exit, even on exception
}

// GOOD: named lock
lock_guard<mutex> data_lock{m};

// BAD: locking multiple mutexes (deadlock risk)
m1.lock();
m2.lock();

// GOOD: deadlock-avoiding lock
scoped_lock lk{m1, m2};
```

## Thread Management

- **Joining thread as scoped container** (CP.23)
- **Prefer `gsl::joining_thread`** (CP.25)
- **Don't `detach()`** (CP.26)
- **Minimize thread creation** (CP.41)

## Data Sharing

- **Small data: pass by value** (CP.31)
- **Shared ownership across threads: `shared_ptr`** (CP.32)
- **Define mutex with guarded data** (CP.50)

## Coroutines

- **No capturing lambdas as coroutines** (CP.51)
- **No locks across suspension points** (CP.52)
- **No reference params to coroutines** (CP.53)

## Anti-Patterns

```cpp
// BAD: volatile for sync
volatile int flag = 0;
flag = 1;  // not atomic, not ordered

// GOOD: atomic
atomic<int> flag{0};
flag.store(1, memory_order_release);

// BAD: detached thread
thread t{work};
t.detach();  // fire-and-forget, hard to manage

// GOOD: joining thread
joining_thread t{work};  // joins on destruction

// BAD: wait without condition
unique_lock lk{m};
cv.wait(lk);  // spurious wakeups possible

// GOOD: wait with predicate
cv.wait(lk, []{ return condition; });
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `concurrency-mt-unsafe` | CP.1-2 |
| `modernize-use-scoped-lock` | CP.20 |
| `bugprone-spuriously-wake-up-functions` | CP.42 |
| `bugprone-bad-signal-to-kill-thread` | CP.26 |
| `cppcoreguidelines-no-suspend-with-lock` | CP.52 |
| `cppcoreguidelines-avoid-capturing-lambda-coroutines` | CP.51 |
| `cppcoreguidelines-avoid-reference-coroutine-parameters` | CP.53 |
| `concurrency-thread-canceltype-asynchronous` | CP.26 |

## References

- **Full rule/checker mapping**: [rules-and-checkers.md](references/rules-and-checkers.md)
