# Resource Lifecycle (HIGH)

**Triggers**: RAII, Drop, resource lifecycle, connection pool, lazy init, OnceCell, LazyLock, OnceLock, scope guard, cleanup, transaction scope.

## Core Question

**When should this resource be created, used, and cleaned up?**

Before implementing resource lifecycle:
- What is the resource's scope and ownership structure?
- Who is responsible for cleanup?
- What happens on error or early return?
- Is the resource expensive to create or destroy?

---

## Lifecycle Pattern Selection

### Pattern Decision Flowchart

```
What is the resource cost?
├─ Cheap (stateless, lightweight)
│   └─ Create per use
├─ Expensive to create (DB connections, TLS)
│   ├─ Global singleton → OnceLock / LazyLock
│   └─ Reusable → Pool (deadpool, r2d2)
└─ Expensive to create AND limited (file handles)
    └─ RAII + Drop

What is the scope?
├─ Function-local → stack allocation or Box
├─ Request-scoped → passed via extractor or parameter
├─ Task-scoped → owned by async task, dropped at end
└─ Application-wide → static, Arc, or OnceLock

What about errors?
├─ Cleanup must happen → Drop (guaranteed)
├─ Cleanup is fallible → explicit close() returning Result
└─ Cleanup is optional → forget() or leak()
```

---

## RAII (Resource Acquisition Is Initialization)

### Basic Pattern

Resources are acquired at construction and released at destruction via `Drop`:

```rust
struct DatabaseConnection {
    inner: Option<InnerConnection>,
}

impl DatabaseConnection {
    fn open(config: &Config) -> Result<Self, Error> {
        let inner = InnerConnection::connect(&config.addr, &config.creds)?;
        Ok(Self { inner: Some(inner) })
    }
}

impl Drop for DatabaseConnection {
    fn drop(&mut self) {
        if let Some(inner) = self.inner.take() {
            inner.disconnect();  // Guaranteed cleanup
        }
    }
}
```

### Guard Pattern

A guard type holds a resource temporarily and restores state on drop:

```rust
struct ScopedTimer<'a> {
    start: Instant,
    label: &'a str,
}

impl<'a> ScopedTimer<'a> {
    fn new(label: &'a str) -> Self {
        Self { start: Instant::now(), label }
    }
}

impl<'a> Drop for ScopedTimer<'a> {
    fn drop(&mut self) {
        tracing::info!("{} took {:?}", self.label, self.start.elapsed());
    }
}

// Usage
fn process_data(data: &[u8]) {
    let _timer = ScopedTimer::new("process_data");
    // ... processing work
}  // _timer dropped here, logs elapsed time
```

### ScopeGuard Pattern

For ad-hoc scope-based cleanup without defining a new type:

```rust
use scopeguard::defer;

fn write_file(path: &str, data: &[u8]) -> Result<(), Error> {
    let file = File::create(path)?;
    defer! { fs::remove_file(path).ok(); }  // Cleanup on unwind
    file.write_all(data)?;
    // On success, prevent cleanup
    Ok(())
}
```

---

## Lazy Initialization

### OnceLock / OnceCell (Lazy One-Time Init)

Use for global state that is initialized once on first access:

```rust
use std::sync::OnceLock;

static CONFIG: OnceLock<AppConfig> = OnceLock::new();

fn get_config() -> &'static AppConfig {
    CONFIG.get_or_init(|| {
        AppConfig::load("config.toml").expect("valid config")
    })
}

// Usage
fn main() {
    let config = get_config();  // Initialized on first call
    println!("{}", config.host);
}
```

### LazyLock (Stable 1.80+)

```rust
use std::sync::LazyLock;

static DATA: LazyLock<Vec<u8>> = LazyLock::new(|| {
    std::fs::read("data.bin").expect("failed to read data")
});

fn process() {
    let data = &*DATA;  // Initialized on first access
}
```

### Thread-Local Lazy

```rust
use std::cell::RefCell;

thread_local! {
    static BUF: RefCell<Vec<u8>> = const { RefCell::new(Vec::new()) };
}

fn use_buffer() {
    BUF.with(|buf| {
        let mut buf = buf.borrow_mut();
        buf.clear();
        // use pre-allocated buffer
    });
}
```

---

## Pooling

### Connection Pools

For expensive resources that should be reused:

```rust
use deadpool_postgres::{Config, Pool, Runtime};

fn create_pool() -> Pool {
    let mut config = Config::new();
    config.url = Some("postgres://...".to_string());
    config.create_pool(Some(Runtime::Tokio1)).unwrap()
}

async fn query(pool: &Pool) -> Result<Vec<Row>, Error> {
    let client = pool.get().await?;  // Acquire from pool
    let rows = client.query("SELECT * FROM users", &[]).await?;
    Ok(rows)
    // client returned to pool on drop
}
```

### Object Pools

```rust
use deadpool::managed::{Config, Manager, Pool, RecycleResult, Object};

struct ExpensiveResource { /* ... */ }

impl Manager for ExpensiveResourceManager {
    type Type = ExpensiveResource;
    type Error = Error;

    async fn create(&self) -> Result<ExpensiveResource, Error> {
        Ok(ExpensiveResource::new().await?)
    }

    async fn recycle(&self, _: &mut ExpensiveResource) -> RecycleResult<Error> {
        Ok(())  // Check if connection is still alive
    }
}
```

---

## Drop Semantics

### Drop Order

- Struct fields drop top-to-bottom (declaration order)
- Locals drop in reverse declaration order
- Variables in `match` arms drop when the arm exits
- Temporary values drop at the end of the statement (or later, per NLL rules)

```rust
struct Droppable(&'static str);
impl Drop for Droppable {
    fn drop(&mut self) { println!("dropping {}", self.0); }
}

fn drop_order() {
    let _a = Droppable("a");
    let _b = Droppable("b");
    // Prints: dropping b, dropping a (reverse order)
}
```

### ManuallyDrop

To prevent drop or control drop timing:

```rust
use std::mem::ManuallyDrop;

fn prevent_drop() {
    let s = String::from("hello");
    let s = ManuallyDrop::new(s);
    // s won't be dropped — ownership was moved into ManuallyDrop
    // SAFETY: we leak the string intentionally
    let ptr = ManuallyDrop::into_raw(s);
}
```

### Drop Guards

Types that exist solely for side effects on drop:

```rust
struct SignalGuard {
    flag: Arc<AtomicBool>,
}

impl Drop for SignalGuard {
    fn drop(&mut self) {
        self.flag.store(true, Ordering::Release);
    }
}

fn spawn_worker() -> SignalGuard {
    let flag = Arc::new(AtomicBool::new(false));
    let guard = SignalGuard { flag: Arc::clone(&flag) };
    std::thread::spawn(move || {
        while !flag.load(Ordering::Acquire) {
            std::thread::sleep(Duration::from_millis(10));
        }
    });
    guard
}
```

---

## Error Path Cleanup

### RAII for Automatic Rollback

```rust
struct Transaction<'conn> {
    conn: &'conn mut Connection,
    committed: bool,
}

impl<'conn> Transaction<'conn> {
    fn begin(conn: &'conn mut Connection) -> Result<Self, Error> {
        conn.execute("BEGIN")?;
        Ok(Self { conn, committed: false })
    }

    fn commit(mut self) -> Result<(), Error> {
        self.conn.execute("COMMIT")?;
        self.committed = true;
        Ok(())
    }
}

impl<'conn> Drop for Transaction<'conn> {
    fn drop(&mut self) {
        if !self.committed {
            self.conn.execute("ROLLBACK").ok();
        }
    }
}

// Usage — rollback is automatic on error
fn transfer(conn: &mut Connection, from: &str, to: &str, amount: f64) -> Result<(), Error> {
    let tx = Transaction::begin(conn)?;
    debit(conn, from, amount)?;   // If this fails...
    credit(conn, to, amount)?;    // ...or this fails...
    tx.commit()?;                  // Only on explicit commit
    Ok(())
}
```

### Cleanup on Early Return

```rust
struct FileLock {
    file: File,
}

impl FileLock {
    fn acquire(path: &str) -> Result<Self, Error> {
        let file = OpenOptions::new()
            .write(true)
            .create(true)
            .open(path)?;
        file.try_lock_exclusive()?;
        Ok(Self { file })
    }
}

impl Drop for FileLock {
    fn drop(&mut self) {
        self.file.unlock().ok();
        // File closed automatically
    }
}
```

---

## Common Mistakes

| Mistake | Why Bad | Fix |
|---------|---------|-----|
| No Drop for resource cleanup | Resource leak | Implement `Drop` |
| Panicking in Drop | Abort or double panic | Never panic in `Drop` |
| Holding locks across .await | Deadlock | Scope lock tightly |
| `mem::forget` without `ManuallyDrop` | Undefined behavior | Use `ManuallyDrop` |
| Manual cleanup with `close()` | Can be skipped | Use RAII + `Drop` |
| Thread::spawn without join handle | Detached thread | Store handle or use scope |

---

## Anti-Patterns

| Anti-Pattern | Why Bad | Better |
|--------------|---------|--------|
| `Box::leak` for all static data | Memory leak, not dropped | `OnceLock` / `LazyLock` |
| Manual `close()` everywhere | Easy to forget | RAII with `Drop` |
| Panic in error path of `Drop` | Abort process | Log error, don't panic |
| Globals without synchronization | Data races | `OnceLock`, `LazyLock`, `Arc` |
| Unbounded resource creation | Resource exhaustion | Pooling with capacity |

---

## Cross-References

- For smart pointer choice: load `ownership`
- For pool implementations: load `collections`
- For async cleanup: load `async`
- For concurrency: load `concurrency`
