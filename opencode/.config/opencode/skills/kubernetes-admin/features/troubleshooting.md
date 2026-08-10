# Troubleshooting — etcd, kubelet, control plane, node/pod failure diagnosis

> Diagnosis is fastest when you start from events and node status, use crictl for container inspection, and remember which tool is for live clusters versus offline data.

## Rules

1. Start diagnosis with `kubectl describe node` and `kubectl get events`; NotReady reasons and eviction signals appear there, and pods are evicted from a NotReady node after five minutes. Why: most node problems surface as events before anything else.
2. Read control plane logs at `/var/log/kube-apiserver.log`, `/var/log/kube-scheduler.log`, `/var/log/kube-controller-manager.log`, and worker logs at `/var/log/kubelet.log` and `/var/log/kube-proxy.log` when not containerized; use `journalctl` on systemd systems.
3. Secure the kubelet HTTPS endpoint (10250): by default the API server does **not** verify the kubelet serving certificate, so use `--kubelet-certificate-authority` or SSH tunneling, and enable kubelet authn/authz. Why: an unverified kubelet channel is a MITM and privilege vector.
4. Inspect containers with `crictl`, the CRI client: `crictl pods`, `crictl ps -a`, `crictl images`, `crictl exec -it <id> <cmd>`, `crictl logs`; configure the endpoint via `/etc/crictl.yaml` or flags. Why: `docker` commands fail or lie when the runtime is containerd/CRI-O.
5. Use `etcdctl` for live cluster operations (health, member list) and `etcdutl` for offline data operations (snapshot status, restore, defrag). Why: `etcdctl snapshot status` is deprecated since etcd v3.5.x and slated for removal in etcd v3.6.
6. Back up etcd with `etcdctl snapshot save <file>` and restore with `etcdutl --data-dir <dir> snapshot restore <file>`. Why: a restore into a mismatched data-dir layout breaks the member.
7. Replace a failed etcd member one at a time: `etcdctl member list`, `etcdctl member remove <id>`, `etcdctl member add <name> --peer-urls=<url>`. Why: replacing multiple members at once risks quorum loss.
8. Check the cgroup driver match between the container runtime and kubelet; a mismatch prevents the node from becoming Ready. Why: runtime and kubelet must agree on the driver.
9. Fix kubelet IP confusion on multi-interface nodes with `--node-ip`; otherwise `kubectl logs`/`kubectl run` may fail because kubelet picked the wrong interface.
10. Treat "Unable to connect to the server: dial tcp ... i/o timeout" as a kubeconfig/network problem; check `~/.kube/config` (or `$KUBECONFIG`/`--kubeconfig`). Why: the error is pre-API, so server-side logs are the wrong place to look first.
11. Debug node-local issues with `kubectl debug node/mynode -it --image=ubuntu`, which runs a debugging pod with host access. Why: it gives a shell without touching the host SSH setup.
12. Match the mitigation to the failure mode: HA control plane for apiserver loss, HA etcd for backing-store loss, network design for partitions, and periodic snapshots for kubelet/backing faults.
13. Remember that a kubelet that cannot reach the API server still runs existing pods. Why: "pods are fine" is not proof the control plane is healthy.

## Good / Bad Examples

Good:
```
crictl ps -a
crictl logs <container-id>
```
Bad: debugging a containerd/CRI-O node with `docker ps`/`docker logs` — those commands do not see CRI containers.

Good:
```
ETCDCTL_API=3 etcdctl --endpoints 10.2.0.9:2379 --cert=... --key=... --cacert=... endpoint health
```
Bad: using `etcdctl snapshot status` for offline snapshots — deprecated since etcd v3.5.x; use `etcdutl snapshot status`.

## Command Recipes

- Node status: `kubectl get nodes`; `kubectl describe node <node>`; `kubectl get events --namespace=<ns>` (docs:tasks/debug/debug-cluster/_index.md:44-63)
- Host kubelet logs: `journalctl -u kubelet` (docs:concepts/cluster-administration/logging.md:184)
- CRI inspection: `crictl ps -a`, `crictl logs <container-id>`, `crictl exec -i -t <container-id> ls` (docs:tasks/debug/debug-cluster/crictl.md:170,201)
- etcd health: `ETCDCTL_API=3 etcdctl --endpoints 10.2.0.9:2379 --cert=... --key=... --cacert=... endpoint health` (docs:tasks/administer-cluster/configure-upgrade-etcd.md:166-170)
- etcd snapshot save: `ETCDCTL_API=3 etcdctl --endpoints $ENDPOINT snapshot save snapshot.db` (docs:tasks/administer-cluster/configure-upgrade-etcd.md:307)
- etcd snapshot status (offline): `etcdutl --write-out=table snapshot status snapshot.db` (docs:tasks/administer-cluster/configure-upgrade-etcd.md:317)
- etcd snapshot restore (offline): `etcdutl --data-dir <dir> snapshot restore snapshot.db` (docs:tasks/administer-cluster/configure-upgrade-etcd.md:430)
- Node debugging pod: `kubectl debug node/mynode -it --image=ubuntu` (docs:tasks/debug/debug-cluster/kubectl-node-debug.md:30)
- Recover kubelet client certs: back up/delete `/etc/kubernetes/kubelet.conf` and `/var/lib/kubelet/pki/kubelet-client*`, regenerate with `kubeadm kubeconfig user --org system:nodes --client-name system:node:$NODE > kubelet.conf`, restart kubelet (docs:setup/production-environment/tools/kubeadm/troubleshooting-kubeadm.md:209-229)

## Version Notes

- `etcdutl` is the current tool for offline snapshot/restore; `etcdctl snapshot status` is deprecated since etcd v3.5.x with removal in etcd v3.6 (docs:tasks/administer-cluster/configure-upgrade-etcd.md:334-348).
- Node log query (`NodeLogQuery`) is **GA** in v1.36, enabling `/logs`-based node service log querying (docs:reference/command-line-tools-reference/feature-gates/NodeLogQuery.md:19-22).
- **FUTURE (v1.37)**: cgroup v1 support is phased out; kubelet fails to initialize on cgroup v1 nodes unless an override is applied (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md:55-63).

## Pitfalls

- Debugging containers with `docker` commands on a runtime that is not docker (containerd/CRI-O) — use `crictl`.
- Using `etcdctl snapshot status` (deprecated) instead of `etcdutl`.
- Restoring an etcd snapshot to a different `--data-dir` without matching the member's expected layout breaks the member.
- Replacing multiple etcd members at once risks quorum loss; replace one at a time.
- Ignoring the cgroup driver mismatch — kubelet and runtime must agree or the node never becomes Ready.
- A kubelet that cannot reach the API server still runs existing pods, so "pods are fine" is not proof the control plane is healthy.

## Cross-References

- For application-level debugging (logs/exec/port-forward, kubectl debug, ephemeral containers, local dev): `../kubernetes-developer/features/debugging.md`

## Doc Refs

- docs:tasks/debug/debug-cluster/_index.md
- docs:tasks/debug/debug-cluster/crictl.md
- docs:tasks/debug/debug-cluster/troubleshoot-kubectl.md
- docs:tasks/debug/debug-cluster/kubectl-node-debug.md
- docs:tasks/administer-cluster/configure-upgrade-etcd.md
- docs:setup/production-environment/tools/kubeadm/troubleshooting-kubeadm.md
- docs:concepts/architecture/control-plane-node-communication.md
- docs:concepts/cluster-administration/logging.md
- docs:tasks/administer-cluster/kubelet-config-file.md
- docs:reference/networking/ports-and-protocols.md
- docs:reference/command-line-tools-reference/feature-gates/NodeLogQuery.md
