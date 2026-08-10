# Deployment Strategies — rolling updates, canary/blue-green, rollback, progressive delivery

> Default to RollingUpdate, use canary/blue-green patterns for controlled exposure, and keep revision history enabled so rollback always works.

## Rules

1. Default to `RollingUpdate` for Deployments: `maxUnavailable` 25% (rounded down) and `maxSurge` 25% (rounded up) bound availability and total Pods; neither may be 0 if the other is 0. Why: the defaults keep availability while bounding burst.
2. Understand terminating Pods are not counted toward `availableReplicas`, so total Pods can transiently exceed `replicas + maxSurge`. Why: availability accounting lags termination.
3. Use `Recreate` only when downtime is acceptable: it kills all old Pods before creating new ones, with no "at most" availability guarantee. Why: Recreate gives no availability bound; use StatefulSet semantics when you need them.
4. Expect rollover on mid-rollout updates: updating creates a new ReplicaSet and starts scaling down the in-flight one. Why: the controller converges to the latest template.
5. Expect proportional scaling: scaling a Deployment mid-rollout distributes new replicas across active ReplicaSets proportionally. Why: scale is spread by template share, not applied to one set.
6. Roll back with `kubectl rollout undo` (optionally `--to-revision=N`); revisions are created only by Pod-template changes and rollback itself creates a new revision. Why: undo replays retained ReplicaSets.
7. Do not `rollout undo` or `pause` a paused Deployment — both are disallowed until resumed. Why: paused Deployments reject rollout verbs.
8. Use `kubectl rollout pause`/`resume` to batch multiple template changes into one rollout. Why: pausing prevents an intermediate rollout per edit.
9. For canary: run a second Deployment with a `track: canary` label alongside `track: stable`, keep the Service selector on the shared subset (`app`, `tier`) so both receive traffic, tune the replica ratio, then promote the stable track and delete the canary. Why: shared selectors split traffic across both tracks.
10. Never include the differentiating label (`track`) in the Service selector, or the canary gets no traffic. Why: the selector must match both tracks to split load.
11. For StatefulSet canary/phased rollouts use `.spec.updateStrategy.rollingUpdate.partition`; only ordinals >= partition update, and a `partition` greater than `replicas` blocks updates. Why: partition is the built-in phased-rollout mechanism for stateful workloads.
12. Use Gateway API traffic weighting and header-based matching for progressive delivery; progressive delivery is not a built-in core API feature. Why: Gateway API is the documented differentiator for gradual traffic shifting.
13. Remember rollouts apply to Deployments, DaemonSets, and StatefulSets. Why: all three controllers implement rollout semantics.
14. When an HPA manages a Deployment, do not set `.spec.replicas` in the manifest. Why: apply would fight the HPA over the replica count.
15. A bad image causes ImagePullBackOff and a stuck rollout; roll back rather than editing forward. Why: the controller stops scaling the new ReplicaSet on template failure.

## Good / Bad Examples

Good (explicit rolling-update bounds):
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```
Bad:
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 0   # invalid: neither may be 0 if the other is 0
```

Good (canary Service selector on the shared subset):
```yaml
selector:
  app: myapp
  tier: frontend     # no track label -> both stable and canary receive traffic
```
Bad:
```yaml
selector:
  app: myapp
  tier: frontend
  track: stable      # canary Deployment never gets traffic
```

Good (StatefulSet partition):
```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 3
```
Bad:
```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 10    # greater than replicas -> blocks all updates
```

## Command Recipes

- Update image or edit: `kubectl set image deployment/nginx-deployment nginx=nginx:1.16.1`; `kubectl edit deployment/nginx-deployment` (docs:concepts/workloads/controllers/deployment.md)
- Watch rollout status: `kubectl rollout status deployment/my-deployment --timeout 10m`; without watch: `kubectl rollout status statefulsets/backing-stateful-component --watch=false` (docs:concepts/workloads/management.md)
- History and rollback: `kubectl rollout history deployment/nginx-deployment --revision=2`; `kubectl rollout undo deployment/nginx-deployment --to-revision=2` (docs:concepts/workloads/controllers/deployment.md)
- Pause/resume batching: `kubectl rollout pause deployment/nginx-deployment`; `kubectl rollout resume deployment/nginx-deployment` (docs:concepts/workloads/controllers/deployment.md)
- Restart in place: `kubectl rollout restart deployment configmap-env-var` (docs:tutorials/configuration/updating-configuration-via-a-configmap.md)
- Patch strategy fields: `kubectl patch deployment/my-nginx --type='merge' -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":"100%"}}}}'` (docs:concepts/workloads/management.md)
- Record change cause: `kubectl annotate deployment/nginx-deployment kubernetes.io/change-cause="image updated to 1.16.1"` (docs:concepts/workloads/controllers/deployment.md)
- StatefulSet rollback: `kubectl rollout undo statefulset/webapp --to-revision=3` (docs:concepts/workloads/controllers/statefulset.md)

## Decision Tables

Deployment strategy choice:

| Strategy | Mechanism | Downtime | Best for |
|---|---|---|---|
| RollingUpdate (default) | scale up new RS, scale down old | minimal, bounded by maxUnavailable | stateless apps, default |
| Recreate | kill all, then create | full | dev/test, immutable infra |
| Canary (manual pattern) | second Deployment + shared selector | none | gradual verification with traffic split |
| Blue-green (manual pattern) | two Deployments, switch Service selector | switch-time only | instant rollback via selector flip |
| StatefulSet partition | ordinal-bound phased update | ordered | stateful phased rollout |

Note: canary and blue-green are patterns assembled from documented primitives (two Deployments + a shared Service selector), not built-in strategies.

## Version Notes

- The `--record` flag that auto-populated CHANGE-CAUSE is deprecated and slated for removal (docs:concepts/workloads/controllers/deployment.md).
- StatefulSet `maxUnavailable` rolling-update field: beta since v1.35, disabled by default in v1.36 (docs:concepts/workloads/controllers/statefulset.md).
- **FUTURE (v1.37)**: no deployment-strategy removals announced; watch the kube-proxy ipvs deprecation and SELinuxMount GA for rollout-affecting changes (SELinux: volumes mounted with `-o context=` may cause Pods sharing a volume with different SELinux labels to fail to start) (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md).

## Pitfalls

- A bad image (e.g. `nginx:1.161`) causes ImagePullBackOff and a stuck rollout; the controller stops scaling the new ReplicaSet (depends on maxUnavailable). Roll back rather than editing forward (docs:concepts/workloads/controllers/deployment.md).
- `kubectl apply` after manual scaling overrides `replicas`; if an HPA manages the Deployment, do not set `.spec.replicas` at all (docs:concepts/workloads/controllers/deployment.md).
- `revisionHistoryLimit: 0` disables rollback (docs:concepts/workloads/controllers/deployment.md).
- Canary Services must not include the differentiating label (`track`) in their selector, or the canary gets no traffic (docs:concepts/workloads/management.md).
- StatefulSet OrderedReady rolling updates can wedge; after reverting a bad template you must also delete the broken Pods manually (docs:concepts/workloads/controllers/statefulset.md).

## Cross-References

- For Deployment/StatefulSet fundamentals: `features/workloads.md`
- For Gateway API traffic weighting: `features/services-networking.md`
- For probes that gate rollout health: `features/resources-probes.md`

## Doc Refs

- docs:concepts/workloads/controllers/deployment.md
- docs:concepts/workloads/controllers/statefulset.md
- docs:concepts/workloads/management.md
- docs:concepts/services-networking/gateway.md
- docs:tutorials/configuration/updating-configuration-via-a-configmap.md
