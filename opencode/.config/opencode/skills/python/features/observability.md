# Python Observability

Agent guidance for instrumenting Python services with structured logs, metrics, and distributed traces. Apply these directives when adding observability to a new service, debugging production behavior, or wiring correlation IDs across request chains. Observability is not optional infrastructure — it is the only way to answer "what happened and why" after a deploy.

## Structured Logging

Enforce structured (JSON) logging in every service that runs outside a developer's terminal. Plain `print` and unstructured `logging.info(f"got {x}")` lines are unqueryable in production. Prefer `structlog` for its context-var binding and JSON renderer; fall back to `logging` with a JSON formatter only when adding a dependency is impossible.

```python
import logging
import structlog

def configure_logging(log_level: str = "INFO") -> None:
    """Configure structlog for JSON output with consistent fields."""
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(
            getattr(logging, log_level.upper())
        ),
        cache_logger_on_first_use=True,
    )
```

Require every log event to carry a stable set of fields: `timestamp`, `level`, `event`, `correlation_id`, and at least one business field (`user_id`, `request_id`, or `job_id`). Bind the log level from configuration — see `configuration.md` for how to wire `LOG_LEVEL` through pydantic-settings. Never log at `ERROR` for expected behavior; a wrong-password attempt is `INFO`, not `ERROR`.

## Prometheus Metrics

Expose Prometheus metrics at a `/metrics` endpoint for every long-running service. Use the four metric primitives deliberately: `Counter` for monotonically increasing values (requests served, errors), `Gauge` for point-in-time values (queue depth, active connections), `Histogram` for distributions (request latency), and `Summary` only when you need client-side quantiles that Prometheus cannot compute from histograms.

```python
from prometheus_client import Counter, Histogram, start_http_server

REQUESTS = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "path", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "Request latency in seconds",
    ["method", "path"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5),
)

def record_request(method: str, path: str, status: int, duration: float) -> None:
    REQUESTS.labels(method=method, path=path, status=str(status)).inc()
    REQUEST_LATENCY.labels(method=method, path=path).observe(duration)
```

Bound label cardinality. Never put user IDs, email addresses, or full URLs in labels — they explode storage and break query performance. Normalize high-cardinality values into a bounded set (route templates, not raw paths) before labeling.

## Distributed Tracing

Propagate trace context across every service boundary using OpenTelemetry. A trace is the only way to reconstruct a request that fans out across multiple services. Auto-instrument HTTP servers, clients, and database drivers; add manual spans only for business logic that auto-instrumentation cannot see.

```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource

trace.set_tracer_provider(TracerProvider(
    resource=Resource.create({"service.name": "orders-api"}),
))
trace.get_tracer_provider().add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint="http://otel-collector:4318"))
)

tracer = trace.get_tracer(__name__)

def charge_payment(order_id: str, amount: int) -> None:
    """Charge payment within a traced span."""
    with tracer.start_as_current_span("charge_payment", attributes={
        "order.id": order_id,
        "payment.amount": amount,
    }) as span:
        result = gateway.charge(order_id, amount)
        span.set_attribute("payment.transaction_id", result.txn_id)
```

Add attributes to spans, not new events, for structured data. Record exceptions with `span.record_exception(exc)` and `span.set_status(StatusCode.ERROR)` so failed operations surface in trace analysis tools.

## Correlation IDs and the Four Golden Signals

Thread a correlation ID from ingress through every log, metric, and span. Generate one at the edge if the caller did not provide it; echo it back in the response header so callers can correlate their own logs. Use `contextvars` so the ID propagates through async code without explicit threading.

```python
from contextvars import ContextVar
import uuid
import structlog

correlation_id: ContextVar[str] = ContextVar("correlation_id", default="")

async def correlation_middleware(request, call_next):
    """Set and propagate correlation ID for the current request."""
    cid = request.headers.get("X-Correlation-ID") or str(uuid.uuid4())
    correlation_id.set(cid)
    structlog.contextvars.bind_contextvars(correlation_id=cid)
    response = await call_next(request)
    response.headers["X-Correlation-ID"] = cid
    return response
```

Track the four golden signals at every service boundary: latency (request duration histogram), traffic (requests-per-second counter), errors (error-rate counter), and saturation (gauge for queue depth, connection pool usage, or CPU). Alert on these before chasing individual log lines. When retry logic emits warnings, cross-reference `resilience.md` for how to log retry attempts without flooding the error channel.

## When to Use

Load this feature file when:
- Adding structured logging to a new service or replacing `print` statements
- Exposing Prometheus metrics or wiring a `/metrics` endpoint
- Setting up OpenTelemetry tracing across service boundaries
- Propagating correlation IDs through async request chains
- Building dashboards or alerts around the four golden signals
- Debugging production behavior where logs alone are insufficient

## Cross-References

- For retry/backoff logging that avoids error-channel flooding: load `resilience.md`
- For binding `LOG_LEVEL` and tracing endpoint configuration: load `configuration.md`
- For async context propagation mechanics that correlation IDs rely on: load `async.md`
- For resource cleanup around metric and trace exporters: load `resource-management.md`