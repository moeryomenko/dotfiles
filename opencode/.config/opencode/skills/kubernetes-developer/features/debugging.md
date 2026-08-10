# Debugging — kubectl logs/exec/port-forward, kubectl debug, ephemeral containers, local dev (kind)

> Debug from the outside in: describe for events, logs for output, exec or debug for a shell, and port-forward for local access.

## Rules

1. Inspect logs with `kubectl logs <pod> -c <container>` and previous-instance logs with `--previous`. Why: `--previous` reads the last crashed instance.
2. `kubectl logs --previous` only works when the container has restarted (a previous instance exists). Why: there is no prior log otherwise.
3. Use `kubectl exec` with `--stdin --tty` (short `-i`/`-t`) and `--container` for multi-container Pods. Why: the short flags match interactive shell usage.
4. `kubectl exec` on a crash-looping container is often impossible; use `kubectl debug --copy-to` or `kubectl logs --previous` instead. Why: exec requires a running process.
5. Use ephemeral containers (stable since v1.25) for interactive troubleshooting when exec is insufficient. Why: ephemeral containers join a running Pod without restarting it.
6. `kubectl debug` can add an ephemeral container to a running Pod with `--target=<container>`; `--target` requires runtime support for process namespaces. Why: without it you cannot see the target's processes.
7. `kubectl debug` can copy a Pod: `--copy-to=<name> --share-processes`, change its command (`--container=<c> -- sh`), or change images (`--set-image=*=<img>`). Why: copying gives a safe sandbox for crash-looping Pods.
8. Use `kubectl debug node/<node>` for node shells; node debug Pods are real Pods — delete them when done. Why: they run privileged on the node.
9. Prefer `--profile=general` over the default `legacy` profile; profiles `baseline`/`restricted` map to Pod Security Standards, and `netadmin`/`sysadmin` grant network/admin capabilities. Why: `legacy` is the default but planned for deprecation.
10. Use `kubectl port-forward` with resource-name targets: `deployment/mongo`, `service/mongo`, or a Pod name; omit the local port (`:27017`) to let kubectl choose it. Why: resource-name targets avoid hard-coding Pod names.
11. `kubectl port-forward` is TCP-only and long-running (does not return until terminated). Why: it maintains a tunnel for the session.
12. `kubectl port-forward` requires RBAC `get` on the resource and `create` on `pods/portforward`. Why: port-forwarding creates a subresource.
13. Diagnose Pod failures in order: `kubectl describe pod` for events, `kubectl get events`, `kubectl get pod <name> -o yaml`, and extract the terminated message with `-o go-template`. Why: events and lastState reveal the failure reason.
14. Node log query (GA v1.36): kubelet API + kubectl plugin read node logs without SSH; requires the `NodeLogQuery` gate and `enableSystemLogQuery` kubelet config. Why: it removes the SSH dependency for log retrieval.
15. For local development use `kind` (Kubernetes IN Docker) or minikube — documented learning environments that run lightweight clusters. Why: a local cluster is the fastest way to iterate on manifests.
16. Debug Service issues by inspecting `kubectl logs` and verifying backing Pods in EndpointSlices. Why: Service problems usually trace to endpoint membership.

## Good / Bad Examples

Good (previous-instance logs):
```
kubectl logs my-pod -c app --previous
```
Bad (invented flag):
```
kubectl logs my-pod -c app --prev   # no such flag
```

Good (debug copy for a crash-looping container):
```
kubectl debug myapp --copy-to=myapp-debug --share-processes --image=busybox
```
Bad (exec on a crash-looping container):
```
kubectl exec -it myapp -- /bin/sh   # often fails: no running process
```

Good (port-forward to a Deployment):
```
kubectl port-forward deployment/mongo 28015:27017
```
Bad:
```
kubectl port-forward mongo:27017   # not a valid target form
```

## Command Recipes

- Logs: `kubectl logs ${POD_NAME} -c ${CONTAINER_NAME}`; `kubectl logs ${POD_NAME} -c ${CONTAINER_NAME} --previous` (docs:tasks/debug/debug-application/debug-running-pod.md)
- Exec: `kubectl exec -it <pod> -- /bin/bash`; `kubectl exec -i -t <pod> --container <c> -- /bin/bash`; `kubectl exec shell-demo -- env` (docs:tasks/debug/debug-application/get-shell-running-container.md)
- Debug ephemeral container: `kubectl debug -it ephemeral-demo --image=busybox:1.28 --target=ephemeral-demo` (docs:tasks/debug/debug-application/debug-running-pod.md)
- Debug copy with process sharing: `kubectl debug <pod> -it --image=<img> --share-processes --copy-to=<pod>-debug` (docs:tasks/debug/debug-application/debug-running-pod.md)
- Debug copy changing command: `kubectl debug <pod> -it --copy-to=<pod>-debug --container=<c> -- sh` (docs:tasks/debug/debug-application/debug-running-pod.md)
- Debug copy changing image: `kubectl debug <pod> --copy-to=<pod>-debug --set-image=*=<img>` (docs:tasks/debug/debug-application/debug-running-pod.md)
- Node debug: `kubectl debug node/<node> -it --image=<img>`; `kubectl debug --profile=sysadmin node/${NODE_NAME} -it --image=ubuntu:latest` (docs:tasks/debug/debug-application/debug-running-pod.md)
- Port-forward: `kubectl port-forward deployment/mongo 28015:27017`; `kubectl port-forward service/mongo 28015:27017`; `kubectl port-forward deployment/mongo :27017` (docs:tasks/access-application-cluster/port-forward-access-application-cluster.md)
- Describe/events: `kubectl describe pod <name>`; `kubectl get events` (docs:tasks/debug/debug-application/debug-pods.md)
- Extract terminated message: `kubectl get pod <name> -o go-template="{{range .status.containerStatuses}}{{.lastState.terminated.message}}{{end}}"` (docs:tasks/debug/debug-application/determine-reason-pod-failure.md)
- Inspect an ephemeral container's security context: `kubectl get pod myapp -o jsonpath='{.spec.ephemeralContainers[0].securityContext}'` (docs:tasks/debug/debug-application/debug-running-pod.md)

## Unverified Flags

- Common log-stream flags (`kubectl logs -f`, `--tail`, `--since`, `--timestamps`, `--all-containers`, `--prefix`) are NOT spelled out in k8s-site task/concept pages (the generated kubectl reference is a stub) — UNVERIFIED; verify against `kubectl logs --help` on v1.36.

## Decision Tables

Debug mode choice:

| Situation | Recommended mode | Why |
|---|---|---|
| Running Pod needs a shell | `kubectl debug -it <pod> --image=<img> --target=<container>` | ephemeral container joins the Pod |
| Crash-looping container | `kubectl debug <pod> --copy-to=<pod>-debug --share-processes` | copy isolates the failure |
| Change entrypoint/image | `kubectl debug <pod> --copy-to=<pod>-debug --container=<c> -- sh` or `--set-image=*=<img>` | reproduce with different parameters |
| Node-level debugging | `kubectl debug node/<node> -it --image=<img>` | privileged node shell |

## Version Notes

- Ephemeral containers: stable since v1.25 (docs:concepts/workloads/pods/ephemeral-containers.md).
- Node log query (`NodeLogQuery`): GA in v1.36, enabled by default on kubelet (docs:reference/command-line-tools-reference/feature-gates/NodeLogQuery.md).
- `kubectl debug` default profile is `legacy` but planned for deprecation — prefer `general` (docs:tasks/debug/debug-application/debug-running-pod.md).
- `.kuberc` beta (v1.34+) separates user preferences from kubeconfig (docs:reference/kubectl/kuberc.md).

## Pitfalls

- `kubectl debug --target` requires container-runtime support for process namespaces; without it you won't see the target's processes (docs:tasks/debug/debug-application/debug-running-pod.md).
- `kubectl port-forward` is TCP-only and long-running (does not return until terminated) (docs:tasks/access-application-cluster/port-forward-access-application-cluster.md).
- `kubectl exec` on a crash-looping container is often impossible — use `kubectl debug --copy-to` or logs `--previous` instead (docs:tasks/debug/debug-application/debug-running-pod.md; docs:tasks/debug/debug-application/get-shell-running-container.md).
- Node debugging Pods are real Pods on the node — delete them when done (`kubectl delete pod node-debugger-...`) (docs:tasks/debug/debug-application/debug-running-pod.md).
- `kubectl logs --previous` only works for containers that have restarted (previous instance exists) (docs:tasks/debug/debug-application/debug-running-pod.md).

## Cross-References

- For workload lifecycle and restart states: `features/workloads.md`
- For probe-driven health diagnosis: `features/resources-probes.md`
- For Service/EndpointSlice debugging: `features/services-networking.md`

## Doc Refs

- docs:tasks/debug/debug-application/debug-running-pod.md
- docs:tasks/debug/debug-application/debug-pods.md
- docs:tasks/debug/debug-application/get-shell-running-container.md
- docs:tasks/debug/debug-application/determine-reason-pod-failure.md
- docs:tasks/debug/debug-application/debug-service.md
- docs:tasks/access-application-cluster/port-forward-access-application-cluster.md
- docs:concepts/workloads/pods/ephemeral-containers.md
- docs:setup/learning-environment/_index.md
- docs:reference/tools/_index.md
- docs:reference/kubectl/kuberc.md
