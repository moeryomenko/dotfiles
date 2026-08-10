# Workloads — Pods, Deployments, StatefulSets, DaemonSets, Jobs/CronJobs

> Choose the controller by its guarantees: Deployments for stateless rollouts, StatefulSets for stable identity/storage, DaemonSets for per-node daemons, Jobs/CronJobs for batch work.

## Rules

1. Use a Deployment for stateless applications; a rollout is triggered only by `.spec.template` changes (image, labels), never by scaling. Why: the controller compares the template to detect the change.
2. Never edit the `pod-template-hash` label the controller adds to every ReplicaSet. Why: it keys template identity and drives rollout bookkeeping.
3. Leave the Deployment strategy defaults unless you need availability trade-offs: `RollingUpdate` with `maxUnavailable` 25% and `maxSurge` 25%; `Recreate` is the only other strategy. Why: the defaults bound downtime while keeping total Pods near `replicas`.
4. Keep `restartPolicy: Always` in Deployment pod templates (it is the default and the only allowed value). Why: Jobs, not Deployments, own restart semantics.
5. `.spec.selector` is required and immutable on Deployments and StatefulSets; changing it requires delete+recreate. Why: mutable selectors would let controllers adopt unintended Pods.
6. Set `progressDeadlineSeconds` (default 600) and watch for the `ProgressDeadlineExceeded` condition; `kubectl rollout status` exits 0 on success and 1 when the deadline is exceeded. Why: stalled rollouts are detected without waiting forever.
7. Keep `revisionHistoryLimit` (default 10) above zero if you want rollback; `revisionHistoryLimit: 0` disables it. Why: rollback replays retained ReplicaSets.
8. Record change intent with the `kubernetes.io/change-cause` annotation instead of the deprecated `--record` flag. Why: `--record` is deprecated and slated for removal.
9. Use a StatefulSet for stable network identity and stable storage: Pods are `$(statefulset)-$(ordinal)`, deployed and deleted in ordinal order, and storage comes from `volumeClaimTemplates`. Why: stateful apps depend on identity and ordering.
10. Provide a Headless Service (`clusterIP: None`) named by `serviceName` for a StatefulSet. Why: per-Pod DNS names like `$(statefulset)-$(ordinal).$(serviceName).$(ns).svc.cluster.local` depend on it.
11. Use `updateStrategy.rollingUpdate.partition` for canary/phased StatefulSet rollouts; only ordinals >= partition update, and a `partition` greater than `replicas` blocks updates. Why: the partition boundary controls how many Pods update.
12. Do not set `terminationGracePeriodSeconds: 0` on StatefulSets; scaling down never deletes PVCs, and the `persistentVolumeClaimRetentionPolicy` (default `Retain`) is gated by `StatefulSetAutoDeletePVC`. Why: the docs call graceful termination mandatory for stable storage.
13. Use a DaemonSet to run a Pod on every (or selected, via nodeSelector/affinity) node; the `selector` is immutable after creation. Why: per-node daemons must track node membership.
14. Delete a DaemonSet with `--cascade=orphan` to leave its Pods running. Why: orphan deletion keeps daemon Pods alive for offline nodes.
15. For Jobs: `restartPolicy` may only be `Never` or `OnFailure` in the pod template; `backoffLimit` defaults to 6; `activeDeadlineSeconds` overrides `backoffLimit`; `ttlSecondsAfterFinished` auto-cleans finished Jobs (TTL controller, stable v1.23). Why: Jobs own their retry semantics, unlike Deployments.
16. Choose `completionMode` `NonIndexed` (default) or `Indexed`; keep Jobs idempotent because Pods may be recreated. Why: retries and node failures can duplicate work.
17. Treat Job terminal conditions correctly: `Complete`/`Failed` are added only after all Pods terminate (v1.31+, gated by `JobManagedBy`/`JobPodReplacementPolicy`, both stable); interim `FailureTarget`/`SuccessCriteriaMet` appear earlier. Why: automation that waits on `Complete` must wait for the final condition.
18. Use CronJobs (batch/v1, stable since v1.21) with a required `spec.jobTemplate`, cron syntax plus `@yearly/@monthly/@weekly/@daily/@hourly` macros, and `?` equivalent to `*`; keep names <=52 chars and schedules free of `CRON_TZ`/`TZ`. Why: the controller appends 11 chars to the name and rejects embedded timezone settings.
19. Set `concurrencyPolicy` (`Allow` default, `Forbid`, `Replace`) and `startingDeadlineSeconds` deliberately: `startingDeadlineSeconds < 10` may skip schedules, and `Forbid` counts skipped runs as missed (>100 missed stops scheduling). Why: the controller checks schedules every ~10s and caps missed runs.
20. `timeZone` in CronJob spec is stable since v1.27; `successfulJobsHistoryLimit` defaults to 3 and `failedJobsHistoryLimit` to 1. Why: history limits bound clutter from repeated runs.
21. Use sidecar containers (restartable init containers with container-level `restartPolicy: Always`) when a helper must live as long as the Pod; they ignore pod-level policy. Why: sidecar restart semantics differ from one-shot init containers.
22. Container-level `restartPolicy` and `restartPolicyRules` are beta (`ContainerRestartRules`, on by default since v1.35); the `RestartAllContainers` action requires `RestartAllContainersOnContainerExits` (beta, on by default since v1.36). Why: per-container exit-code conditions give finer restart control.
23. In v1.36, Workload Aware Scheduling (WAS) is alpha: new `Workload` and `PodGroup` APIs for gang-style scheduling, with Job controller integration gated. Why: WAS is not yet a stable scheduling contract.

## Good / Bad Examples

Good (Deployment with required selector and restartPolicy):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app.kubernetes.io/name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: nginx
  template:
    metadata:
      labels:
        app.kubernetes.io/name: nginx
    spec:
      restartPolicy: Always
      containers:
        - name: nginx
          image: nginx:1.16.1
```
Bad (missing required selector):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  template:            # no spec.selector — rejected
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx:1.16.1
```

Good (Job restartPolicy):
```yaml
apiVersion: batch/v1
kind: Job
spec:
  template:
    spec:
      restartPolicy: OnFailure
```
Bad:
```yaml
apiVersion: batch/v1
kind: Job
spec:
  template:
    spec:
      restartPolicy: Always   # rejected in Job pod templates
```

Good (CronJob with timeZone and concurrency control):
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/1 * * * *"
  timeZone: Europe/Berlin
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
```
Bad:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: a-cronjob-name-that-is-way-too-long-and-will-be-rejected-after-11-chars-are-appended
spec:
  schedule: "CRON_TZ=UTC */1 * * * *"   # embedded TZ rejected; name > 52 chars
  jobTemplate:
    spec:
      template:
        spec:
          restartPolicy: Never
```

## Command Recipes

- Create/apply a workload: `kubectl apply -f <deployment.yaml>` (docs:concepts/workloads/controllers/deployment.md)
- Inspect workloads: `kubectl get deployments`, `kubectl get rs`, `kubectl get pods --show-labels`, `kubectl describe deployment` (docs:concepts/workloads/controllers/deployment.md)
- Rollout status with a timeout: `kubectl rollout status deployment/my-deployment --timeout 10m`; without watch: `kubectl rollout status statefulsets/backing-stateful-component --watch=false` (docs:concepts/workloads/management.md)
- Rollout history and rollback: `kubectl rollout history deployment/nginx-deployment --revision=2`; `kubectl rollout undo deployment/nginx-deployment --to-revision=2` (docs:concepts/workloads/controllers/deployment.md)
- Pause/resume to batch template changes: `kubectl rollout pause deployment/nginx-deployment`; `kubectl rollout resume deployment/nginx-deployment` (docs:concepts/workloads/controllers/deployment.md)
- Restart in place after config changes: `kubectl rollout restart deployment configmap-env-var` (docs:tutorials/configuration/updating-configuration-via-a-configmap.md)
- Update image and scale: `kubectl set image deployment/nginx-deployment nginx=nginx:1.16.1`; `kubectl scale deployment/nginx-deployment --replicas=10`; `kubectl autoscale deployment/nginx-deployment --min=10 --max=15 --cpu-percent=80%` (docs:concepts/workloads/controllers/deployment.md)
- Set resources per container: `kubectl set resources deployment/nginx-deployment -c=nginx --limits=cpu=200m,memory=512Mi` (docs:concepts/workloads/controllers/deployment.md)
- Patch a Deployment field: `kubectl patch deployment/nginx-deployment -p '{"spec":{"progressDeadlineSeconds":600}}'` (docs:concepts/workloads/controllers/deployment.md)
- StatefulSet scale/rollback/revisions: `kubectl scale statefulset <name> --replicas=X`; `kubectl rollout undo statefulset/webapp --to-revision=3`; `kubectl get controllerrevisions -l app.kubernetes.io/name=webapp`; `kubectl get controllerrevision/webapp-3 -o yaml` (docs:concepts/workloads/controllers/statefulset.md)
- DaemonSet delete leaving Pods: `kubectl delete daemonset <name> --cascade=orphan` (docs:concepts/workloads/controllers/daemonset.md)
- CronJob imperative create: `kubectl create cronjob hello --image=busybox --schedule="*/1 * * * *"` (docs:tasks/job/automated-tasks-with-cron-jobs.md)
- Events: `kubectl get events`, `kubectl get events --namespace=my-namespace`, `kubectl get events --sort-by=.metadata.creationTimestamp` (docs:tasks/debug/debug-application/debug-running-pod.md; docs:reference/kubectl/quick-reference.md)

## Decision Tables

Controller choice:

| Controller | Use when | Distinct guarantee |
|---|---|---|
| Deployment | Stateless apps, rolling updates | Rollout/rollback, no stable identity |
| StatefulSet | Stable identity + storage | Ordered identity, stable PVCs |
| DaemonSet | One Pod per node | Per-node membership |
| Job / CronJob | Batch, scheduled work | Completion semantics, retries |

## Version Notes

- StatefulSet `maxUnavailable` rolling-update field: beta since v1.35, disabled by default in v1.36 (docs:concepts/workloads/controllers/statefulset.md).
- `MutablePodResourcesForSuspendedJobs`: beta, enabled by default since v1.36 (docs:reference/command-line-tools-reference/feature-gates/MutablePodResourcesForSuspendedJobs.md).
- `DeploymentReplicaSetTerminatingReplicas`: beta since v1.35, enabled by default; adds `.status.terminatingReplicas` (docs:reference/command-line-tools-reference/feature-gates/DeploymentReplicaSetTerminatingReplicas.md).
- `InPlacePodVerticalScaling`: GA/locked since v1.35 (docs:reference/command-line-tools-reference/feature-gates/InPlacePodVerticalScaling.md).
- `PodLevelResources`: beta, enabled by default since v1.34 (docs:reference/command-line-tools-reference/feature-gates/PodLevelResources.md).
- Sidecar containers: stable/locked since v1.33 (docs:reference/command-line-tools-reference/feature-gates/SidecarContainers.md).
- **FUTURE (v1.37)**: Static Pods can no longer reference Secrets/ConfigMaps; the `PreventStaticPodAPIReferences` gate is removed (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md).

## Pitfalls

- Deleting a Deployment deletes its Pods (downtime); use `--cascade=orphan` to keep them, and remember selector changes require delete+recreate (docs:concepts/workloads/controllers/deployment.md).
- Rollback is impossible with `revisionHistoryLimit: 0`; old ReplicaSets may exceed the limit during crash-loop rollouts (docs:concepts/workloads/controllers/deployment.md).
- StatefulSet ordered updates can wedge on a never-ready Pod; after fixing the template you must also delete the broken Pods (forced rollback) (docs:concepts/workloads/controllers/statefulset.md).
- Job pods with `restartPolicy: Always` are rejected; unmanaged Jobs leave orphaned Pods after deletion unless `ttlSecondsAfterFinished` is set (docs:concepts/workloads/controllers/job.md).
- `kubectl rollout undo`/`pause` on a paused Deployment is disallowed until it is resumed (docs:concepts/workloads/controllers/deployment.md).
- StatefulSet `terminationGracePeriodSeconds: 0` is unsafe and strongly discouraged (docs:concepts/workloads/controllers/statefulset.md).

## Cross-References

- For selector/label authoring and Kustomize: `features/manifests.md`
- For rollout strategy details: `features/deployment-strategies.md`
- For resources/probes that gate readiness: `features/resources-probes.md`
- For debugging workload failures: `features/debugging.md`

## Doc Refs

- docs:concepts/workloads/controllers/deployment.md
- docs:concepts/workloads/controllers/statefulset.md
- docs:concepts/workloads/controllers/daemonset.md
- docs:concepts/workloads/controllers/job.md
- docs:concepts/workloads/controllers/cron-jobs.md
- docs:concepts/workloads/pods/pod-lifecycle.md
- docs:concepts/workloads/pods/init-containers.md
- docs:concepts/workloads/management.md
- docs:tasks/job/automated-tasks-with-cron-jobs.md
- docs:tasks/debug/debug-application/debug-running-pod.md
- docs:tutorials/configuration/updating-configuration-via-a-configmap.md
- docs:reference/command-line-tools-reference/feature-gates/ (per-gate pages)
