# Python Background Jobs

Agent guidance for decoupling long-running or unreliable work from request/response cycles. Apply these directives when an operation exceeds a few seconds, when work must survive process restarts, or when a service integrates with unreliable external systems. Return a job ID immediately; let workers handle the heavy lifting asynchronously.

## Task Queue Selection

Choose the queue by workload shape, not popularity. Use Celery for mature, feature-rich task processing (routing, priorities, beat scheduling, broad broker support). Use RQ (Redis Queue) for simpler codebases that need Redis-backed jobs without Celery's configuration surface. Use arq for async-native applications where the worker and the producer share an asyncio event loop. Never hand-roll a queue on a database table unless the throughput is trivial — you will rebuild every queue pattern (visibility timeouts, retries, dead letters) poorly.

```python
from celery import Celery

app = Celery("tasks", broker="redis://localhost:6379")

@app.task(bind=True, max_retries=3, default_retry_delay=60)
def send_email(self, to: str, subject: str, body: str) -> None:
    """Send email with automatic retry on transient broker failures."""
    try:
        mailer.send(to, subject, body)
    except ConnectionError as exc:
        raise self.retry(exc=exc, countdown=2 ** self.request.retries * 60)
```

Configure task routing to keep fast, high-priority jobs on a separate queue from slow, low-priority ones. A single shared queue lets a long export job block time-sensitive notification sends.

## Task Queue Patterns

Design every task for idempotency and at-least-once delivery. Workers crash, brokers redeliver, and retries re-execute — a task that double-charges a customer on retry is a production incident. Use idempotency keys for external service calls, check-before-write guards for internal state, and deduplication windows for operations that cannot be made naturally idempotent.

```python
from celery import Celery

app = Celery("tasks", broker="redis://localhost:6379")

@app.task(bind=True)
def process_order(self, order_id: str) -> None:
    """Process order idempotently — safe to retry on any failure."""
    order = orders_repo.get(order_id)
    if order.status == OrderStatus.COMPLETED:
        return  # Already processed; no-op on redelivery

    payment_provider.charge(
        amount=order.total,
        idempotency_key=f"order-{order_id}",
    )
    orders_repo.update(order_id, status=OrderStatus.COMPLETED)
```

Route permanently failed tasks to a dead letter queue (DLQ) after exhausting retries. Never silently drop failed jobs — a DLQ preserves them for inspection and manual reprocessing. Distinguish transient failures (network, timeout, rate limit — retry) from permanent failures (validation error, bad credentials — do not retry, send straight to DLQ). For retry/backoff mechanics, cross-reference `resilience.md`.

## Worker Management

Configure concurrency, prefetch, and graceful shutdown deliberately. Set `worker_prefetch_multiplier=1` for long-running or memory-heavy tasks so a worker does not hoard jobs it cannot start promptly. Enable `task_acks_late=True` so a crash mid-task returns the job to the queue rather than losing it. Wire graceful shutdown: stop accepting new tasks, finish in-flight work, then exit.

```python
from celery import Celery

app = Celery("tasks", broker="redis://localhost:6379")

app.conf.update(
    task_time_limit=3600,
    task_soft_time_limit=3000,
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    worker_prefetch_multiplier=1,
    broker_connection_retry_on_startup=True,
)
```

Set both a hard `task_time_limit` and a softer `task_soft_time_limit`. The soft limit raises `SoftTimeLimitExceeded`, which the task can catch to clean up; the hard limit kills the worker process. Monitor queue depth and worker lag — a growing backlog means either more workers, less work per task, or a downstream dependency failing slowly.

## Scheduling

Use Celery beat for periodic tasks when the project already runs Celery — it shares the broker and worker infrastructure. Use APScheduler when the application needs in-process scheduling without a separate broker, or for jobs that must run on a single instance with cron-like precision. Never rely on `time.sleep` loops or OS cron for tasks that require retry, observability, or horizontal scaling.

```python
from celery import Celery
from celery.schedules import crontab

app = Celery("tasks", broker="redis://localhost:6379")

app.conf.beat_schedule = {
    "cleanup-expired-sessions": {
        "task": "tasks.cleanup_sessions",
        "schedule": crontab(hour=3, minute=0),
    },
    "hourly-metrics-rollup": {
        "task": "tasks.rollup_metrics",
        "schedule": 3600.0,
    },
}
```

Ensure scheduled tasks are themselves idempotent — beat may fire a task twice during a deploy or a beat restart. Log every schedule invocation with a correlation ID so overlapping runs are distinguishable in traces.

## When to Use

Load this feature file when:
- An operation takes longer than a few seconds and should not block the request
- Sending emails, notifications, or webhooks asynchronously
- Generating reports, exports, or media transformations in the background
- Integrating with unreliable external services that need retry and DLQ handling
- Setting up Celery, RQ, or arq workers with correct concurrency and prefetch
- Scheduling periodic jobs via Celery beat or APScheduler

## Cross-References

- For retry/backoff and circuit-breaker mechanics that queue retries rely on: load `resilience.md`
- For structured logging of job state transitions and correlation IDs: load `observability.md`
- For async task patterns when using arq or async workers: load `async.md`
- For configuration of broker URLs and worker settings: load `configuration.md`