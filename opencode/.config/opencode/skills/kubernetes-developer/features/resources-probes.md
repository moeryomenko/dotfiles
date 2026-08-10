# Resources & Probes — requests/limits, QoS classes, liveness/readiness/startup probes

> Requests are a scheduling promise, limits are an enforcement ceiling, and the three probe types answer three different health questions.

## Rules

1. Set per-container `resources.requests`/`resources.limits` for `cpu`, `memory`, `ephemeral-storage`, `hugepages-<size>`, and extended resources; the Pod aggregate request/limit is the sum of its containers. Why: the scheduler places on requests and the kubelet enforces limits.
2. Express CPU in cpu units (0.1 == 100m; 1m = 0.001 CPU) and memory in bytes — use `Ki`/`Mi`/`Gi` for memory, never `k`/`M`/`G`, and never write `400m` for memory (it means 0.4 bytes). Why: unit case changes the value by orders of magnitude.
3. Expect CPU limits to be enforced by throttling and memory limits reactively by OOM kills under pressure. Why: a container can transiently exceed its memory limit before the kernel reacts.
4. Do not overcommit `hugepages-*`; hugepages cannot be overcommitted. Why: hugepages are physically reserved.
5. Achieve `Guaranteed` QoS by setting cpu and memory requests equal to limits on every container (all > 0); `Burstable` has some request/limit set but not Guaranteed; `BestEffort` has no cpu/memory requests or limits. Why: QoS class drives eviction order and OOM scores.
6. Expect eviction under node pressure in order: BestEffort, then Burstable (only those exceeding requests), then Guaranteed. Why: the classes encode priority under memory pressure.
7. Remember QoS class is fixed at Pod creation; an in-place resize that would change the QoS class is rejected by admission. Why: resize must not silently change guarantees.
8. Use startup, liveness, and readiness probes distinctly: startup runs only at startup and gates liveness/readiness until it succeeds; liveness failure kills/restarts the container; readiness failure removes the Pod from Service EndpointSlices without restarting it. Why: each probe answers a different question.
9. Pick exactly one probe mechanism per probe: `exec` (exit 0 = success), `grpc` (SERVING status), `httpGet` (2xx-3xx success), `tcpSocket` (port open). Why: mixing mechanisms is not allowed.
10. Tune probe fields: `initialDelaySeconds` (default 0), `periodSeconds` (default 10, min 1), `timeoutSeconds` (default 1, min 1), `successThreshold` (default 1; must be 1 for liveness/startup), `failureThreshold` (default 3). Why: defaults favor fast failure detection.
11. Reserve probe-level `terminationGracePeriodSeconds` for liveness/startup probes — it is rejected on readiness probes (stable since v1.28). Why: readiness probes never terminate containers.
12. HTTP probes succeed on status >= 200 and < 400, follow same-host redirects only, and stop reading the body after 10 KiB. Why: the 10 KiB cap avoids draining the node; off-host redirects produce a ProbeWarning.
13. For apps that need more than `initialDelaySeconds + failureThreshold x periodSeconds` to start, add a startup probe against the same endpoint with a high failureThreshold, leaving liveness defaults intact. Why: the startup probe holds liveness off until the app is truly ready.
14. gRPC probes are stable since v1.27; TCP probes connect from the node and cannot resolve Service names in `host`. Why: node-level connectivity has no in-cluster DNS.
15. Use liveness for unrecoverable failure only; use readiness for load-dependent health. Why: a misconfigured liveness probe causes cascading restarts and lost traffic.
16. Pod-level `resources.requests/limits` (cpu/memory/hugepages) is available under `PodLevelResources` (beta, on by default since v1.34). Why: pod-level resources simplify the spec for single-container Pods.
17. In-place Pod resize via the `/resize` subresource is GA (`InPlacePodVerticalScaling`, locked since v1.35); `resizePolicy` controls whether a restart is required. Why: resize avoids replacement Pods when limits change.

## Good / Bad Examples

Good (request/limit pairing):
```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 200m
    memory: 256Mi
```
Bad (memory unit mistake):
```yaml
resources:
  requests:
    cpu: 100m
    memory: 400m   # 0.4 bytes, not 400 MiB
```

Good (startup probe guarding a slow start):
```yaml
startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
```
Bad (invalid successThreshold on liveness):
```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  successThreshold: 3   # must be 1 for liveness/startup -> rejected
```

## Command Recipes

- Apply the documented probe examples: `kubectl apply -f https://k8s.io/examples/pods/probe/exec-liveness.yaml`, then `kubectl describe pod liveness-exec` (docs:tasks/configure-pod-container/configure-liveness-readiness-startup-probes.md)
- In-place resize of a running Pod (command syntax UNVERIFIED in k8s-site — the docs reference the `/resize` subresource conceptually; verify against `kubectl patch --help` on v1.36): `kubectl patch pod <name> --subresource=resize -p '{"spec":{"containers":[{"name":"app","resources":{"requests":{"cpu":"200m"}}}]}}'` (docs:tasks/configure-pod-container/resize-container-resources.md)

## Decision Tables

QoS class:

| QoS class | Condition | Eviction priority under node pressure |
|---|---|---|
| Guaranteed | every container cpu+memory requests == limits, all > 0 | lowest |
| Burstable | some request/limit set, not Guaranteed | medium (only those exceeding requests) |
| BestEffort | no cpu/memory requests or limits | highest |

Probe type choice:

| Probe | Purpose | Failure behavior |
|---|---|---|
| startup | slow-starting apps | gates liveness/readiness until success |
| liveness | unrecoverable health | kubelet kills/restarts the container |
| readiness | load-dependent health | removed from EndpointSlices; no restart |

## Version Notes

- Probe-level `terminationGracePeriodSeconds`: stable since v1.28 (docs:concepts/workloads/pods/probes.md).
- gRPC probes: stable since v1.27 (docs:concepts/workloads/pods/probes.md).
- `InPlacePodVerticalScaling`: GA/locked since v1.35 (docs:reference/command-line-tools-reference/feature-gates/InPlacePodVerticalScaling.md).
- Memory QoS (memory.high/memory.min tiering on cgroup v2): alpha behind `MemoryQoS`, disabled by default; separate from QoS class assignment (docs:reference/command-line-tools-reference/feature-gates/MemoryQoS.md).
- `allocatedResourcesStatus` in Pod `.status` (device health: Unhealthy/Unknown): beta in v1.36 — helps diagnose crash loops caused by hardware (blog:_posts/2026/kubernetes-v1-36-release/index.md).

## Pitfalls

- Liveness probes must indicate unrecoverable failure; misconfigured liveness under load causes cascading restarts and lost traffic (docs:concepts/workloads/pods/probes.md).
- Memory limits are enforced reactively — a container can exceed its limit and later be OOM-killed under pressure; plan headroom (docs:concepts/configuration/manage-resources-containers.md).
- Setting requests != limits prevents `Guaranteed` QoS (silently Burstable) and can block static CPU-policy eligibility (docs:concepts/workloads/pods/pod-qos.md).
- Requesting `400m` memory instead of `400Mi` requests 0.4 bytes (docs:concepts/configuration/manage-resources-containers.md).
- HTTP probes cut connections at 10 KiB bodies, surfacing as broken-pipe/reset errors in app logs (docs:concepts/workloads/pods/probes.md).
- Probe-level `terminationGracePeriodSeconds` on readiness probes is rejected by the API server (docs:concepts/workloads/pods/probes.md).

## Cross-References

- For in-place resize and workload lifecycle: `features/workloads.md`
- For resource fields in manifests: `features/manifests.md`
- For diagnosing crash loops/restarts: `features/debugging.md`

## Doc Refs

- docs:concepts/configuration/manage-resources-containers.md
- docs:concepts/workloads/pods/pod-qos.md
- docs:concepts/workloads/pods/probes.md
- docs:tasks/configure-pod-container/configure-liveness-readiness-startup-probes.md
- docs:tasks/configure-pod-container/assign-memory-resource.md
- docs:tasks/configure-pod-container/assign-cpu-resource.md
- docs:tasks/configure-pod-container/resize-container-resources.md
- docs:reference/command-line-tools-reference/feature-gates/InPlacePodVerticalScaling.md
