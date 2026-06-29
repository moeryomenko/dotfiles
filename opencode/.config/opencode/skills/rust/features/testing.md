# Testing (MEDIUM)

**Triggers**: test, #[test], #[cfg(test)], integration test, unit test, mock, property-based, proptest, benchmark, criterion, snapshot test, insta, doctest, loom, fuzz.

## Put Unit Tests in `#[cfg(test)] mod tests`

Within each module, with `use super::*;` to access private items:

```rust
fn private_helper() -> i32 { 21 }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_private_helper() {
        assert_eq!(private_helper(), 21);  // Can test private!
    }
}
```

## Use `use super::*;` in Test Modules

Provides access to all parent module items, including private functions.

## Put Integration Tests in the `tests/` Directory

Each file in `tests/` becomes a separate integration test crate. These can only test public API.

## Use Descriptive Test Names

```rust
#[test]
fn parse_valid_json_returns_expected_struct() { /* ... */ }
```

## Structure Tests with Arrange-Act-Assert

```rust
#[test]
fn test_calculate_discount() {
    // Arrange
    let price = 100.0;
    let user = User::new_premium();
    
    // Act
    let discount = calculate_discount(price, &user);
    
    // Assert
    assert!((discount - 20.0).abs() < f64::EPSILON);
}
```

## Use Proptest for Property-Based Testing

```rust
use proptest::prelude::*;

proptest! {
    #[test]
    fn reverse_twice_is_identity(mut vec: Vec<i32>) {
        vec.reverse();
        vec.reverse();
        assert_eq!(vec, input);
    }
}
```

## Use Mockall for Trait Mocking

```rust
#[automock]
trait Database {
    fn query(&self, id: u64) -> Option<User>;
}

// In test:
let mut mock = MockDatabase::new();
mock.expect_query()
    .with(predicate::eq(42))
    .returning(|_| Some(User::default()));
```

## Use Traits for Dependencies to Enable Mocking

```rust
trait DataSource {
    fn fetch(&self) -> Result<Data>;
}

struct Service<T: DataSource> {
    source: T,
}
```

## Use RAII Pattern for Automatic Test Cleanup

```rust
struct TempDir {
    path: PathBuf,
}

impl Drop for TempDir {
    fn drop(&mut self) {
        fs::remove_dir_all(&self.path).ok();
    }
}
```

## Use `#[tokio::test]` for Async Tests

```rust
#[tokio::test]
async fn test_async_operation() {
    let result = async_function().await;
    assert!(result.is_ok());
}
```

## Use `#[should_panic]` for Expected Panics

```rust
#[test]
#[should_panic(expected = "index out of bounds")]
fn test_out_of_bounds() {
    let v = vec![1];
    v[10];  // Expected to panic
}
```

## Use `criterion` for Benchmarking

```rust
use criterion::{black_box, criterion_group, Criterion};

fn bench_compute(c: &mut Criterion) {
    c.bench_function("compute", |b| {
        b.iter(|| compute(black_box(42)))
    });
}
```

## Keep Documentation Examples as Executable Doctests

```rust
/// Adds two numbers.
/// ```
/// assert_eq!(add(2, 3), 5);
/// ```
fn add(a: i32, b: i32) -> i32 { a + b }
```

## Use `loom` for Concurrency Testing

Exhaustively test lock-free and concurrent code with loom's permutation testing.

## Use Snapshot Testing (insta) for Complex Output

```rust
#[test]
fn test_serialize_complex() {
    let output = serialize(&complex_data);
    insta::assert_snapshot!(output);
}
```

## Cross-References

- For doc conventions: load `documentation`
- For async test setup: load `async`
