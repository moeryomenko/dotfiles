# Observability — metrics, logs, events, kube-state-metrics, audit

> Observability is complete when metrics, logs, and traces are all collected, the resource-metrics pipeline feeds autoscaling, and audit logs are enabled with a policy file.

## Rules

1. Treat observability as three pillars: metrics, logs, and traces. Why: each pillar answers a different failure question.
2. Scrape control plane components (kube-apiserver, kube-controller-manager, kube-scheduler, kubelet, kube-proxy, etcd) on `/metrics`; the kubelet additionally exposes `/metrics/cadvisor`, `/metrics/resource`, and `/metrics/probes`. Why: per-component endpoints need separate scrape jobs and auth.
3. Use kubelet PSI (Pressure Stall Information) metrics, GA in v1.36, exposed at `/metrics/cadvisor` as cumulative counters. Why: PSI reveals resource-pressure stalls that CPU/memory utilization hides.
4. Deploy kube-state-metrics as an add-on agent that exposes cluster object state (e.g., `kube_pod_container_info`) for queries and alerting. Why: kubelet metrics alone do not describe object health.
5. Keep the resource metrics pipeline intact: kubelet `/metrics/resource` and `/stats` to metrics-server, to the `metrics.k8s.io` API, then to HPA/VPA and `kubectl top`. Why: HPA/VPA cannot work without metrics-server even if raw `/metrics` is scraped.
6. Use `kubectl top node` and `kubectl top pod` to read the Metrics API.
7. Watch events with `kubectl events`, using `--for TYPE/NAME`, `--watch`, `--types=Normal,Warning`, and `-A/--all-namespaces`. Why: short-lived pod events are missed without `--watch` or a field selector.
8. Read container logs with `kubectl logs` (stdout/stderr via the CRI), `--previous` for the last terminated container; at most 10MiB of log data is returned. Why: beyond 10MiB you need `--tail` or the file under `/var/log/pods`.
9. Know where system logs live: control plane components typically run in containers (`kubectl logs -n kube-system <pod>`), while kubelet and the container runtime run on the host (`journalctl -u kubelet`); node-level logs live under `/var/log`. Why: reaching the right log source halves diagnosis time.
10. Enable audit logging with `--audit-policy-file`; it is required, and if omitted no events are logged. Why: audit is silently disabled without the policy file.
11. Choose audit stages (`RequestReceived`, `ResponseStarted`, `ResponseComplete`) and levels (`None`, `Metadata`, `Request`, `RequestResponse`), and set log backend flags `--audit-log-path`, `--audit-log-maxage`, `--audit-log-maxbackup`, `--audit-log-maxsize`.
12. Run Node Problem Detector as a daemon (DaemonSet or standalone) to report node problems from kernel/daemon logs. Why: node-level faults often never reach workload-level signals.
13. Query node service logs via the `/logs` endpoint under the `NodeLogQuery` feature gate, **GA** in v1.36 (default true). Why: it avoids SSH for routine node log access.

## Good / Bad Examples

Good:
```
kubectl top node
kubectl top pod --namespace=NAMESPACE
kubectl events --for pod/web-pod-13je7 --watch
```
Bad: scraping kubelet `/metrics` directly and assuming HPA works — the autoscaling pipeline still needs metrics-server.

Good (audit policy):
```
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
```
Bad: running kube-apiserver without `--audit-policy-file` — audit logging is silently disabled.

## Command Recipes

- Node/pod metrics: `kubectl top node [NODE_NAME]`, `kubectl top pod --namespace=NAMESPACE`; flags include `--sort-by` and `--no-headers` (docs:reference/kubectl/generated/kubectl_top/kubectl_top_node.md:38,41,61,89; kubectl_top_pod.md:40,43)
- Events: `kubectl events --for pod/web-pod-13je7 --watch`, `kubectl events --types=Warning,Normal`, `kubectl events -A` (docs:reference/kubectl/generated/kubectl_events/_index.md:42-51)
- Legacy event listing: `kubectl get events` (docs:tasks/debug/debug-application/debug-running-pod.md:197,203)
- Container logs: `kubectl logs counter`, `kubectl logs counter -c count`, `kubectl logs --previous` (docs:concepts/cluster-administration/logging.md:59,70,75)
- Host kubelet logs: `journalctl -u kubelet` (docs:concepts/cluster-administration/logging.md:184)

## Version Notes

- PSI metrics are GA in v1.36 (blog:_posts/2026/kubernetes-v1-36-release/index.md:560).
- Node log query (`NodeLogQuery`) is **GA** in v1.36, default true — enables querying node service logs via the `/logs` endpoint (docs:reference/command-line-tools-reference/feature-gates/NodeLogQuery.md:19-22).
- Audit feature-state wording: the older `securing-a-cluster.md` page describes audit as beta; treat that wording as historical because the audit task page does not label it alpha/beta/GA. Whether v1.36 docs change the audit feature state is **UNVERIFIED**.
- **FUTURE (v1.37)**: the `metrics.k8s.io` API is expected to graduate to GA (stable) after ~9 years in beta; both v1 and v1beta1 will remain usable (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md:82-86).

## Pitfalls

- Scraping `/metrics` of the kubelet without considering metrics-server: HPA/VPA still need the full resource metrics pipeline.
- `kubectl logs` truncates at 10MiB; use `--tail` or the file under `/var/log/pods` for full history.
- Not rotating logs: system component and container logs under `/var/log` grow unbounded unless rotated.
- Omitting the audit policy file entirely disables audit logging silently.
- Relying on events without `--watch`/`--field-selector` misses short-lived pod events — use `kubectl get events --field-selector involvedObject.name=<pod>` style queries or `kubectl events --for`.

## Doc Refs

- docs:concepts/cluster-administration/observability.md
- docs:concepts/cluster-administration/system-metrics.md
- docs:concepts/cluster-administration/kube-state-metrics.md
- docs:concepts/cluster-administration/logging.md
- docs:tasks/debug/debug-cluster/resource-metrics-pipeline.md
- docs:tasks/debug/debug-cluster/resource-usage-monitoring.md
- docs:tasks/debug/debug-cluster/monitor-node-health.md
- docs:tasks/debug/debug-cluster/audit.md
- docs:reference/kubectl/generated/kubectl_events/_index.md
- docs:reference/kubectl/generated/kubectl_top/kubectl_top_node.md
- docs:reference/kubectl/generated/kubectl_top/kubectl_top_pod.md
- docs:reference/instrumentation/understand-psi-metrics.md
- docs:reference/command-line-tools-reference/feature-gates/NodeLogQuery.md
