# Capacity & Scheduling — ResourceQuotas, LimitRanges, HPA/VPA, priority classes, taints/tolerations

> Capacity is predictable when quotas bound the namespace, LimitRanges shape per-pod defaults, autoscaling has a working metrics pipeline, and taints/tolerations express intent explicitly.

## Rules

1. Use ResourceQuota to constrain aggregate per-namespace consumption: compute `requests.cpu`, `requests.memory`, `limits.cpu`, `limits.memory`, and `count/<resource>` object counts; the `ResourceQuota` admission plugin must be enabled for enforcement. Why: for `cpu`/`memory`, every pod in the namespace must specify requests/limits when a quota exists.
2. Use LimitRange to constrain per-pod min/max/default requests and limits plus `maxLimitRequestRatio`; validation happens only at pod admission. Why: a LimitRange never affects already-running pods, and multiple LimitRanges make defaults nondeterministic.
3. Prefer HPA with `autoscaling/v2`, the only served version since v1.26; it supports resource, object, external, and pods metric types and configurable `behavior` (scaleUp/scaleDown policies with stabilization). Why: v2beta2 manifests using `targetAverageUtilization` are rejected.
4. Install VPA as a separate CRD-based component (`autoscaling.k8s.io/v1` stable API) with recommender, updater, and admission webhook; it requires metrics-server. Why: VPA is not built into the control plane.
5. Choose VPA update modes deliberately: `Off`, `Initial`, `Recreate`, `InPlaceOrRecreate`, `InPlace`. Why: in-place updates depend on `InPlacePodVerticalScaling`, GA (stable, locked) since v1.35.
6. Define PriorityClass (`scheduling.k8s.io/v1`) with integer `value` up to 1 billion; at most one `globalDefault` exists cluster-wide, and `preemptionPolicy` defaults to `PreemptLowerPriority` (`Never` disables preemption). Why: priority decides which pods are preempted first under contention.
7. Use the built-in `system-cluster-critical` and `system-node-critical` PriorityClasses for control plane and system pods. Why: reserving them prevents user workloads from starving the cluster.
8. Apply taints with `kubectl taint nodes node1 key1=value1:NoSchedule`; effects are `NoSchedule`, `NoExecute`, and `PreferNoSchedule`. Why: only `NoExecute` evicts already-scheduled pods (with `tolerationSeconds` limiting the grace).
9. Write tolerations with `operator` defaulting to `Equal`; `Exists` matches without a value, an empty key with `Exists` matches all keys, and `tolerationSeconds` bounds `NoExecute` tolerance. Why: an omitted `tolerationSeconds` on `NoExecute` means tolerate forever.
10. Expect kube-scheduler to filter nodes for feasibility (e.g., `PodFitsResources`), then score the feasible nodes and pick the highest; ties break by round-robin, and behavior is configurable via policies or plugins.
11. Monitor node-pressure eviction signals: `memory.available`, `nodefs.available`, `imagefs.available`, `imagefs.inodesFree`; hard thresholds use 0s grace, soft thresholds use `evictionSoftGracePeriod`. Why: node-pressure eviction is the kubelet's last-resort capacity control.

## Good / Bad Examples

Good:
```
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: acme
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi
```
Bad: creating a `cpu`/`memory` ResourceQuota in a namespace where existing pods omit requests/limits — new pod creation is blocked in that namespace.

Good:
```
kubectl taint nodes node1 key1=value1:NoSchedule
```
Bad: using `NoExecute` on critical workloads without a toleration with `tolerationSeconds` — they are evicted immediately.

## Command Recipes

- Create quota: `kubectl create quota <name> --hard=requests.cpu=1,limits.memory=2Gi` — exact `kubectl create quota` flag spelling is **UNVERIFIED** against the kubectl reference; verify before scripting (imperative form of the manifest at docs:concepts/policy/resource-quotas.md:288-296)
- Inspect quota: `kubectl get resourcequota`, `kubectl describe quota <name>` (docs:reference/kubernetes-api/core/resource-quota-v1.md)
- Create an HPA: `kubectl autoscale deployment php-apache --cpu=50% --min=1 --max=10` (docs:tasks/run-application/horizontal-pod-autoscale-walkthrough.md:103)
- Taint a node: `kubectl taint nodes node1 key1=value1:NoSchedule`; remove with a trailing `-`: `kubectl taint nodes node1 key1=value1:NoSchedule-` (docs:concepts/scheduling-eviction/taint-and-toleration.md:35-44)
- List priority classes: `kubectl get priorityclasses` (docs:reference/kubernetes-api/scheduling/priority-class-v1.md)
- Inspect scheduling events: `kubectl describe pod <name>` shows Unschedulable reasons (docs:tasks/debug/debug-application/debug-pods.md:33-63)

## Decision Table

| Concern | ResourceQuota | LimitRange |
|---|---|---|
| Scope | namespace aggregate | per Pod / per container |
| Constrains | total requests/limits, `count/<resource>` | min/max/default requests & limits, `maxLimitRequestRatio` |
| Enforced | admission via the ResourceQuota plugin | admission, per Pod creation |
| Effect on running pods | none (new Pods blocked if quota exceeded) | none (admission-time only) |
| Typical use | hard cap on namespace consumption | default values and per-Pod bounds |

Use ResourceQuota for namespace-wide budgets and LimitRange for per-Pod sizing defaults; they are complementary, not interchangeable.

## Version Notes

- HPA `autoscaling/v2` is the only served version since v1.26 (`v2beta2` removed) (docs:reference/using-api/deprecation-guide.md:75-82).
- VPA stable API is `autoscaling.k8s.io/v1`; VPA is a separate install (CRD) (docs:concepts/workloads/autoscaling/vertical-pod-autoscale.md:44-46).
- `InPlacePodVerticalScaling` is GA since v1.35 (stable, locked, default true) (docs:reference/command-line-tools-reference/feature-gates/InPlacePodVerticalScaling.md:14-20).
- PriorityClass `scheduling.k8s.io/v1` is the only served version since v1.22 (docs:reference/using-api/deprecation-guide.md:288-294).
- **FUTURE (v1.37)**: the Metrics API (`metrics.k8s.io`) is expected to graduate to GA; v1 and v1beta1 both remain usable (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md:82-86).

## Pitfalls

- Creating a ResourceQuota for `cpu`/`memory` when existing pods omit requests/limits blocks new pod creation in that namespace.
- Adding a LimitRange does not affect already-running pods — it is admission-time only.
- Multiple LimitRanges in one namespace make default assignment nondeterministic.
- HPA with `--cpu-percent`-style flags that reference v2beta2 behavior; the current API uses `target.averageUtilization` in manifests.
- Deleting a PriorityClass does not change existing pods but blocks creation of new pods referencing it.
- Using a `NoExecute` taint without `tolerationSeconds` on critical workloads causes immediate eviction.
- Forgetting that a node taint does not remove already-scheduled pods unless the taint is `NoExecute`.

## Doc Refs

- docs:concepts/policy/resource-quotas.md
- docs:concepts/policy/limit-range.md
- docs:concepts/workloads/autoscaling/horizontal-pod-autoscale.md
- docs:tasks/run-application/horizontal-pod-autoscale-walkthrough.md
- docs:concepts/workloads/autoscaling/vertical-pod-autoscale.md
- docs:concepts/scheduling-eviction/pod-priority-preemption.md
- docs:concepts/scheduling-eviction/taint-and-toleration.md
- docs:concepts/scheduling-eviction/kube-scheduler.md
- docs:concepts/scheduling-eviction/node-pressure-eviction.md
- docs:reference/command-line-tools-reference/feature-gates/InPlacePodVerticalScaling.md
- docs:reference/using-api/deprecation-guide.md
- docs:reference/kubernetes-api/core/resource-quota-v1.md
- docs:reference/kubernetes-api/scheduling/priority-class-v1.md
