# C++ Concurrency (CP Section)

Guidelines for multi-threaded programming, locks, atomics, and coroutines.

## Fundamental Principles

1. **Assume multi-threaded**: all code may run in a concurrent context
2. **Avoid data races**: two threads accessing same non-atomic variable, at least one writes
3. **Minimize shared writable data**: less sharing = fewer bugs
4. **Think in tasks, not threads**: work with higher-level abstractions
5. **Don't use `volatile` for synchronization**: volatile does not provide atomicity or ordering

```cpp
// volatile for synchronization (broken)
volatile bool ready = false;
// Thread 1: ready = true;  // Not atomic, not ordered
// Thread 2: while (!ready); // May never see the write

// atomic for synchronization
std::atomic<bool> ready{false};
// Thread 1: ready.store(true, std::memory_order_release);
// Thread 2: while (!ready.load(std::memory_order_acquire));
```

## Locking (RAII Only)

| Guideline | Anti-Pattern |
|-----------|-------------|
| Use RAII for locks | `m.lock()` / `m.unlock()` — exception-unsafe |
| Multiple mutexes: `std::lock` or `scoped_lock` | Sequential `lock_guard` — deadlock risk |
| Don't call unknown code under lock | Callback under lock — deadlock, inversion |
| Name your lock guards | Unnamed `lock_guard` — confusing scope |
| Define mutex with guarded data | Separate mutex and data — easy to forget |

```cpp
// Manual lock/unlock (exception-unsafe)
std::mutex m;
m.lock();
do_work();      // If this throws, m stays locked
m.unlock();

// RAII lock
std::mutex m;
{
    std::lock_guard<std::mutex> lk{m};
    do_work();  // Unlocked on scope exit, even on exception
}

// Unnamed lock (unclear what it guards)
std::mutex m;
{
    std::lock_guard<std::mutex>{"???"};  // Temporary, destroyed immediately
    modify_shared_data();
}

// Named lock
std::mutex m;
{
    std::lock_guard<std::mutex> data_lock{m};
    modify_shared_data();
}

// Sequential locks (deadlock risk)
void transfer(Account& a, Account& b, int amount) {
    std::lock_guard lk1(a.mtx);
    std::lock_guard lk2(b.mtx);
}

// Deadlock-avoiding lock
void transfer(Account& a, Account& b, int amount) {
    std::scoped_lock lk(a.mtx, b.mtx);
    // Uses std::lock algorithm to avoid deadlock
}
```

### Mutex and Data Together

```cpp
// Mutex and data are separate — easy to access data without lock
std::mutex mtx;
std::vector<int> shared_data;

void unsafe_access() {
    shared_data.push_back(42);  // Forgot to lock mtx — data race
}

// Mutex and data are coupled
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

| Guideline | Why |
|-----------|-----|
| Joining thread as scoped container | Ensures cleanup |
| Prefer `gsl::joining_thread` | Auto-joins on destruction |
| Don't `detach()` | Fire-and-forget, hard to manage |
| Minimize thread creation | Expensive, prefer thread pool |

### JoiningThread Pattern

```cpp
// Detached thread
void background_work() {
    std::thread t{do_work};
    t.detach();  // Process exits before thread finishes — lost work
}

// Joining thread
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
// Wait without predicate (spurious wakeup)
std::unique_lock lk{m};
cv.wait(lk);  // May wake up spuriously

// Wait with predicate
std::unique_lock lk{m};
cv.wait(lk, []{ return data_ready; });
```

### Atomic Usage

```cpp
// Non-atomic counter (race)
int counter = 0;
// Thread 1: ++counter;  // Read-modify-write race
// Thread 2: ++counter;  // Both may read 0, both write 1

// Atomic counter
std::atomic<int> counter{0};
// Thread 1: ++counter;  // Atomic increment
// Thread 2: ++counter;  // Result: 2

// Separate atomic operations (race possible)
std::atomic<bool> flag{false};
if (!flag.load()) {
    flag.store(true);  // Race: two threads may enter
}

// Atomic exchange (safe)
if (flag.exchange(true)) {  // Only one thread gets false
    // Critical section
}
```

## Coroutines

| Guideline | Why |
|-----------|-----|
| No capturing lambdas as coroutines | Lambda captures are local, coroutine outlives scope |
| No locks across suspension points | Lock held during suspension blocks other threads |
| No reference parameters to coroutines | References may dangle after suspension |

```cpp
// Lock across suspension point (blocks other threads)
std::mutex m;
std::generator<int> bad_generator() {
    std::lock_guard lk{m};
    co_yield 1;  // m locked while suspended — blocks
    co_yield 2;
}

// Lock within non-suspending section
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

| Check | Purpose |
|-------|---------|
| `concurrency-mt-unsafe` | Detect thread-unsafe functions |
| `modernize-use-scoped-lock` | Replace nested lock_guard with scoped_lock |
| `bugprone-spuriously-wake-up-functions` | Detect missing predicate in wait |
| `bugprone-bad-signal-to-kill-thread` | Detect dangerous thread signals |
| `cppcoreguidelines-no-suspend-with-lock` | Detect lock held across suspension |
| `cppcoreguidelines-avoid-capturing-lambda-coroutines` | Detect lambda captures in coroutines |
| `cppcoreguidelines-avoid-reference-coroutine-parameters` | Detect ref params in coroutines |

## Cross-References

- For locking in class design: load `classes`
- For exception safety in multi-threaded code: load `error-handling`
- For lock-free patterns and memory ordering: load `performance`
- For clang-tidy configuration: load `clang-tidy`
