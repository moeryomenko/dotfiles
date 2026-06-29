# Common Concurrency Errors & Fixes

## E0277: Cannot Send Between Threads

### Error Pattern

```rust
use std::rc::Rc;

let data = Rc::new(42);
std::thread::spawn(move || {
    println!("{}", data);  // ERROR: Rc<i32> cannot be sent between threads
});
```

### Fix Options

**Option 1: Use Arc instead**
```rust
use std::sync::Arc;

let data = Arc::new(42);
let data_clone = Arc::clone(&data);
std::thread::spawn(move || {
    println!("{}", data_clone);  // OK: Arc is Send
});
```

**Option 2: Move owned data (Copy types)**
```rust
let data = 42;  // i32 is Copy and Send
std::thread::spawn(move || {
    println!("{}", data);  // OK
});
```

---

## E0277: Cannot Share Between Threads (Not Sync)

### Error Pattern

```rust
use std::cell::RefCell;
use std::sync::Arc;

let data = Arc::new(RefCell::new(42));
// ERROR: RefCell is not Sync
```

### Fix Options

**Option 1: Use Mutex for thread-safe interior mutability**
```rust
use std::sync::{Arc, Mutex};

let data = Arc::new(Mutex::new(42));
```

**Option 2: Use RwLock for read-heavy workloads**
```rust
use std::sync::{Arc, RwLock};

let data = Arc::new(RwLock::new(42));
```

---

## Deadlock Patterns

### Lock Ordering Deadlock

```rust
// DANGER: potential deadlock with inconsistent lock ordering
// Thread 1: locks a then b
// Thread 2: locks b then a  ← Opposite order = deadlock

// FIX: Always lock in the same order
std::thread::spawn(move || {
    let _a = a1.lock().unwrap();  // same order everywhere
    let _b = b1.lock().unwrap();
});

std::thread::spawn(move || {
    let _a = a2.lock().unwrap();  // same order
    let _b = b2.lock().unwrap();
});
```

### Self-Deadlock

```rust
// DANGER: locking same mutex twice (std::Mutex)
let m = Mutex::new(42);
let _g1 = m.lock().unwrap();
let _g2 = m.lock().unwrap();  // DEADLOCK on std::Mutex

// FIX: use parking_lot::ReentrantMutex if reentrancy needed
// Better: restructure code to avoid double-locking
```

---

## Mutex Guard Across Await

### Error Pattern

```rust
use std::sync::Mutex;

async fn bad_async() {
    let m = Mutex::new(42);
    let guard = m.lock().unwrap();
    tokio::time::sleep(Duration::from_secs(1)).await;  // BAD
    println!("{}", *guard);
}
```

### Fix Options

**Option 1: Scope the lock**
```rust
async fn good_async() {
    let m = Mutex::new(42);
    let value = {
        let guard = m.lock().unwrap();
        *guard  // copy value
    };  // guard dropped here
    sleep(Duration::from_secs(1)).await;
    println!("{}", value);
}
```

**Option 2: Use tokio::sync::Mutex**
```rust
use tokio::sync::Mutex;

async fn good_async() {
    let m = Mutex::new(42);
    let guard = m.lock().await;  // async lock
    sleep(Duration::from_secs(1)).await;  // OK with tokio::Mutex
    println!("{}", *guard);
}
```

---

## Data Race Prevention

### Missing Synchronization

```rust
// This WON'T compile - Rust prevents data races
use std::sync::Arc;

let data = Arc::new(0);
let d1 = Arc::clone(&data);

std::thread::spawn(move || {
    // *d1 += 1;  // ERROR: cannot mutate through Arc
});
```

### Fix: Add Synchronization

```rust
use std::sync::{Arc, Mutex};
use std::sync::atomic::{AtomicI32, Ordering};

// Option 1: Mutex
let data = Arc::new(Mutex::new(0));

// Option 2: Atomic (for simple types)
let data = Arc::new(AtomicI32::new(0));
let d1 = Arc::clone(&data);
std::thread::spawn(move || {
    d1.fetch_add(1, Ordering::SeqCst);
});
```

---

## Channel Errors

### Disconnected Channel

```rust
use std::sync::mpsc;

let (tx, rx) = mpsc::channel();
drop(tx);  // sender dropped
match rx.recv() {
    Ok(v) => println!("{}", v),
    Err(_) => println!("channel disconnected"),
}
```

### Fix: Handle Disconnection

```rust
// Iterate (stops on disconnect)
for msg in rx {
    handle(msg);
}

// Or use try_recv for non-blocking
loop {
    match rx.try_recv() {
        Ok(msg) => handle(msg),
        Err(TryRecvError::Empty) => continue,
        Err(TryRecvError::Disconnected) => break,
    }
}
```

---

## Thread Panic Handling

### Proper Error Handling

```rust
let handle = std::thread::spawn(|| {
    panic!("oops");
});

match handle.join() {
    Ok(result) => println!("Success: {:?}", result),
    Err(e) => println!("Thread panicked: {:?}", e),
}

// For async: catch_unwind
use std::panic;

async fn safe_task() {
    let result = panic::catch_unwind(|| {
        risky_operation()
    });

    match result {
        Ok(v) => use_value(v),
        Err(_) => log_error("task panicked"),
    }
}
```

---

## Async Common Errors

### Forgetting to Spawn

```rust
// WRONG: future not polled, does nothing
fn process() {
    fetch_data();  // returns Future that's dropped immediately
}

// RIGHT: await or spawn
async fn process() {
    let data = fetch_data().await;
}
```

### Blocking in Async Context

```rust
// WRONG: blocks the executor
async fn bad() {
    std::thread::sleep(Duration::from_secs(1));  // blocks!
}

// RIGHT: use async versions
async fn good() {
    tokio::time::sleep(Duration::from_secs(1)).await;
}

// For CPU work: spawn_blocking
async fn compute() -> i32 {
    tokio::task::spawn_blocking(|| {
        heavy_computation()
    }).await.unwrap()
}
```
