# C++ Concurrency (CP Section)

Guidelines for multi-threaded programming, locks, atomics, and coroutines.

## Fundamental Principles

1. **Assume multi-threaded** (CP.1): all code may run in a concurrent context
2. **Avoid data races** (CP.2): two threads accessing same non-atomic variable, at least one writes
3. **Minimize shared writable data** (CP.3): less sharing = fewer bugs
4. **Think in tasks, not threads** (CP.4): work with higher-level abstractions
5. **Don't use `volatile` for synchronization** (CP.8): volatile does not provide atomicity or ordering

```cpp
// BAD: volatile for synchronization
volatile bool ready = false;
// Thread 1: ready = true;  // Not atomic, not ordered
// Thread 2: while (!ready); // May never see the write

// GOOD: atomic for synchronization
std::atomic<bool> ready{false};
// Thread 1: ready.store(true, std::memory_order_release);
// Thread 2: while (!ready.load(std::memory_order_acquire));
```

## Locking (RAII Only)

| Rule | Guideline | Anti-Pattern |
|------|-----------|-------------|
| CP.20 | Use RAII for locks | `m.lock()` / `m.unlock()` — exception-unsafe |
| CP.21 | Multiple mutexes: `std::lock` or `scoped_lock` | Sequential `lock_guard` — deadlock risk |
| CP.22 | Don't call unknown code under lock | Callback under lock — deadlock, inversion |
| CP.44 | Name your lock guards | Unnamed `lock_guard` — confusing scope |
| CP.50 | Define mutex with guarded data | Separate mutex and data — easy to forget |

```cpp
// BAD: manual lock/unlock (exception-unsafe)
std::mutex m;
m.lock();
do_work();      // If this throws, m stays locked
m.unlock();

// GOOD: RAII lock
std::mutex m;
{
    std::lock_guard<std::mutex> lk{m};
    do_work();  // Unlocked on scope exit, even on exception
}

// BAD: unnamed lock (unclear what it guards)
std::mutex m;
{
    std::lock_guard<std::mutex>{"???"};  // Temporary, destroyed immediately
    modify_shared_data();
}

// GOOD: named lock
std::mutex m;
{
    std::lock_guard<std::mutex> data_lock{m};
    modify_shared_data();
}

// BAD: sequential locks (deadlock risk)
void transfer(Account& a, Account& b, int amount) {
    std::lock_guard lk1(a.mtx);
    std::lock_guard lk2(b.mtx);
    // If another thread calls transfer(b, a, ...), deadlock
}

// GOOD: deadlock-avoiding lock
void transfer(Account& a, Account& b, int amount) {
    std::scoped_lock lk(a.mtx, b.mtx);
    // Uses std::lock algorithm to avoid deadlock
}
```

### Mutex and Data Together

```cpp
// BAD: mutex and data are separate — easy to access data without lock
std::mutex mtx;
std::vector<int> shared_data;

void unsafe_access() {
    shared_data.push_back(42);  // Forgot to lock mtx — data race
}

// GOOD: mutex and data are coupled
class SharedData {
    mutable std::mutex mtx_;
    std::vector<int> data_;
public:
    void add(int value) {
        std::lock_guard lk{mtx_};
        data_.push_back(value);
    }

    std::vector<int> snapshot() const {
        std::lock_guard lk{mtx_};
        return data_;  // Return copy while locked
    }
};
```

## Thread Management

| Rule | Guideline | Why |
|------|-----------|-----|
| CP.23 | Joining thread as scoped container | Ensures cleanup |
| CP.25 | Prefer `gsl::joining_thread` | Auto-joins on destruction |
| CP.26 | Don't `detach()` | Fire-and-forget, hard to manage |
| CP.41 | Minimize thread creation | Expensive, prefer thread pool |

### JoiningThread Pattern

```cpp
// BAD: detached thread
void background_work() {
    std::thread t{do_work};
    t.detach();  // Process exits before thread finishes — lost work
}

// GOOD: joining thread
class joining_thread {
    std::thread t_;
public:
    explicit joining_thread(std::thread t) : t_(std::move(t)) {}
    ~joining_thread() { if (t_.joinable()) t_.join(); }
    joining_thread(joining_thread&&) = default;
    joining_thread& operator=(joining_thread&&) = default;
};
```

## Data Sharing

### Condition Variables

```cpp
// BAD: wait without predicate (spurious wakeup)
std::unique_lock lk{m};
cv.wait(lk);  // May wake up spuriously

// GOOD: wait with predicate
std::unique_lock lk{m};
cv.wait(lk, []{ return data_ready; });

// Or equivalently:
while (!data_ready) {
    cv.wait(lk);
}
```

### Atomic Usage

```cpp
// BAD: non-atomic counter
int counter = 0;
// Thread 1: ++counter;  // Read-modify-write race
// Thread 2: ++counter;  // Both may read 0, both write 1

// GOOD: atomic counter
std::atomic<int> counter{0};
// Thread 1: ++counter;  // Atomic increment
// Thread 2: ++counter;  // Result: 2

// BAD: separate atomic operations
std::atomic<bool> flag{false};
if (!flag.load()) {
    flag.store(true);  // Race: two threads may both enter
}

// GOOD: atomic exchange
if (flag.exchange(true)) {  // Only one thread gets false
    // Critical section
}
```

## Coroutines

| Rule | Guideline | Why |
|------|-----------|-----|
| CP.51 | No capturing lambdas as coroutines | Lambda captures are local, coroutine outlives scope |
| CP.52 | No locks across suspension points | Lock held during suspension blocks other threads |
| CP.53 | No reference parameters to coroutines | References may dangle after suspension |

```cpp
// BAD: lock across suspension point
std::mutex m;
std::generator<int> bad_generator() {
    std::lock_guard lk{m};
    co_yield 1;  // m locked while suspended — BAD
    co_yield 2;
}

// GOOD: lock within non-suspending section
std::generator<int> good_generator() {
    int val;
    {
        std::lock_guard lk{m};
        val = compute_under_lock();
    }
    co_yield val;
}
```

## Key Clang-Tidy Checks

| Check | Rule |
|-------|------|
| `concurrency-mt-unsafe` | CP.1-2 |
| `modernize-use-scoped-lock` | CP.20 |
| `bugprone-spuriously-wake-up-functions` | CP.42 |
| `bugprone-bad-signal-to-kill-thread` | CP.26 |
| `bugprone-signal-to-kill-thread` | CP.26 |
| `cppcoreguidelines-no-suspend-with-lock` | CP.52 |
| `cppcoreguidelines-avoid-capturing-lambda-coroutines` | CP.51 |
| `cppcoreguidelines-avoid-reference-coroutine-parameters` | CP.53 |
| `concurrency-thread-canceltype-asynchronous` | CP.26 |

## Cross-References

- For locking in class design: load `classes`
- For exception safety in multi-threaded code: load `error-handling`
- For lock-free patterns and memory ordering: load `performance`
- For clang-tidy configuration: load `clang-tidy`
