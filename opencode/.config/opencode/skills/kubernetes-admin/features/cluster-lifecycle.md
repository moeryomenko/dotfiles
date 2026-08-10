# Cluster Lifecycle — kubeadm install, upgrade, drain/cordon, version skew

> Cluster lifecycle work is upgrade-safe when every node is drained first, the control plane is upgraded in order, and version skew stays within policy.

## Rules

1. Bootstrap production clusters with kubeadm; `kubeadm init` runs prechecks that warn and exit on errors before creating the control plane. Why: prechecks catch host prerequisites before a partially broken cluster exists.
2. Record the join command from `kubeadm init` output; a join needs `--token` and `--discovery-token-ca-cert-hash sha256:<hash>`. Why: the CA hash pins the joining node to the expected control plane identity.
3. Pass `--control-plane-endpoint` (an IP or DNS name) to `kubeadm init` and the same name to every `kubeadm join` for a shared load-balanced endpoint. Why: a single control plane created without it cannot later become an HA cluster without re-provisioning.
4. Install a CNI-compliant pod network after `kubeadm init`; the CNI plugin assigns pod IPs and the API server and kubelet communicate over that network.
5. Copy or merge the generated admin kubeconfig manually; kubeadm does not place `admin.conf` or `super-admin.conf` into `~/.kube/config`. Why: `super-admin.conf` carries super-user privileges that bypass RBAC and should not become the default context.
6. Drain every node, including control plane nodes, before `kubeadm upgrade`; uncordon each node afterward. Why: draining evicts workloads so upgrade work does not interrupt them, and PodDisruptionBudgets are respected.
7. Upgrade in the kubeadm order: `kubeadm upgrade plan`, then `kubeadm upgrade apply v1.36.x` on the first control plane, then `kubeadm upgrade node` on the remaining control plane and worker nodes.
8. Respect the supported version skew for a v1.36 apiserver: kubelet at most three minor versions older and never newer, kube-proxy the same as kubelet, and kube-controller-manager, kube-scheduler, and cloud-controller-manager within one minor version older. Why: skew beyond policy is unsupported and fails in unpredictable ways.
9. Use a kubeadm binary whose version matches the components it manages: same or one older for managed components, the same version for `kubeadm join` as for `kubeadm init`/`kubeadm upgrade`, and same MINOR or one newer on upgraded nodes.
10. Upgrade manual (non-kubeadm) clusters in the order etcd, kube-apiserver, kube-controller-manager, kube-scheduler, cloud-controller-manager, then nodes (drain, upgrade kubelet, uncordon).
11. Run `sudo kubeadm reset` for teardown; it performs best-effort cleanup and you must re-run `kubeadm init`/`kubeadm join` to start over. Why: reset does not restore data, so a single-control-plane cluster with local etcd may need recreation after a control-plane failure.
12. Expect cgroups v2 only on Linux nodes in v1.36; the `FailCgroupV1` kubelet option defaults to true. Why: cgroup v1 support is being phased out.
13. Configure kubelet via `kubelet.config.k8s.io/v1beta1` with `--config`; flag and config-file defaults differ for some parameters, and kubeadm propagates cluster-level defaults through its `KubeletConfiguration` API.

## Good / Bad Examples

Good:
```
sudo kubeadm init --control-plane-endpoint=cluster-endpoint --pod-network-cidr=10.244.0.0/16
```
Bad: `sudo kubeadm init --pod-network-cidr=10.244.0.0/16` and later trying to add more control-plane nodes — without `--control-plane-endpoint` an HA conversion requires re-provisioning.

Good:
```
kubectl drain node1 --ignore-daemonsets --delete-emptydir-data
kubectl uncordon node1
```
Bad: `kubectl drain node1` without `--ignore-daemonsets` — the drain hangs on DaemonSet pods; without `--force` bare pods block the drain.

## Command Recipes

- Initialize: `sudo kubeadm init --control-plane-endpoint=cluster-endpoint --pod-network-cidr=10.244.0.0/16`, then install the CNI provider YAML (docs:setup/production-environment/tools/kubeadm/create-cluster-kubeadm.md:179)
- Join worker: `kubeadm join <control-plane-host>:<control-plane-port> --token <token> --discovery-token-ca-cert-hash sha256:<hash>` (docs:setup/production-environment/tools/kubeadm/create-cluster-kubeadm.md:245)
- Upgrade: `sudo kubeadm upgrade plan`, then `sudo kubeadm upgrade apply v1.36.x` on the first control plane, `sudo kubeadm upgrade node` on the remaining control plane and worker nodes (docs:tasks/administer-cluster/kubeadm/kubeadm-upgrade.md:172,188,222)
- Recover a failed upgrade: `sudo kubeadm upgrade apply --force` without changing the version (docs:tasks/administer-cluster/kubeadm/kubeadm-upgrade.md:322)
- Drain/uncordon: `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data` and `kubectl uncordon <node>` (docs:tasks/administer-cluster/safely-drain-node.md:85; flags at docs:reference/kubectl/generated/kubectl_drain/_index.md:68,110)
- Certificates: `kubeadm certs check-expiration` and `kubeadm certs renew all`; `kubeadm upgrade` renews certificates automatically (docs:reference/setup-tools/kubeadm/generated/kubeadm_certs/_index.md; renewal at docs:tasks/administer-cluster/kubeadm/kubeadm-upgrade.md:179)
- Config migration across kubeadm API versions: `kubeadm config migrate --old-config <file> --new-config <file>` (docs:reference/setup-tools/kubeadm/generated/kubeadm_config/kubeadm_config_migrate.md:34)
- Teardown: `sudo kubeadm reset` (docs:setup/production-environment/tools/kubeadm/create-cluster-kubeadm.md:477)

## Version Notes

- kubeadm config API: both `kubeadm.k8s.io/v1beta3` and `kubeadm.k8s.io/v1beta4` reference pages ship in the v1.36 tree; use `kubeadm config migrate` to move between them (docs:reference/config-api/kubeadm-config.v1beta3.md, docs:reference/config-api/kubeadm-config.v1beta4.md).
- Kubelet configuration drop-in directory (`--config-dir`) is GA since v1.35 — current v1.36 behavior (blog:_posts/2025/kubelet-config-drop-in-directory-ga.md:10-14).
- In-place Pod Vertical Scaling (InPlacePodVerticalScaling) is stable (GA, locked) since v1.35, default true (docs:reference/command-line-tools-reference/feature-gates/InPlacePodVerticalScaling.md:14-20).
- **FUTURE (v1.37)**: cgroup v1 support is being phased out; `failCgroupV1` still defaults true and the override remains available in v1.37, with removal planned in a future release (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md:55-63).
- **FUTURE (v1.37)**: kubelet running in user namespaces (rootless mode) is expected to graduate to GA (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md:94).

## Pitfalls

- Installing a different kubeadm MINOR than the kubelet/control-plane components causes skew that surfaces as unexpected kubelet/API behavior; install the same minor everywhere.
- Tolerating `node.kubernetes.io/unschedulable` outside DaemonSets schedules pods onto drained nodes; only DaemonSets should tolerate it.
- Running `kubeadm upgrade apply` on a non-first control-plane node, or before draining, can produce inconsistent control plane state; drain first and follow the documented order.
- `kubeadm reset` does not restore data; back up etcd before destructive changes.

## Doc Refs

- docs:setup/production-environment/tools/kubeadm/install-kubeadm.md
- docs:setup/production-environment/tools/kubeadm/create-cluster-kubeadm.md
- docs:tasks/administer-cluster/kubeadm/kubeadm-upgrade.md
- docs:tasks/administer-cluster/safely-drain-node.md
- docs:tasks/administer-cluster/cluster-upgrade.md
- releases:version-skew-policy.md
- docs:tasks/administer-cluster/kubelet-config-file.md
- docs:setup/production-environment/tools/kubeadm/kubelet-integration.md
- docs:reference/kubectl/generated/kubectl_drain/_index.md
- docs:reference/setup-tools/kubeadm/generated/kubeadm_config/kubeadm_config_migrate.md
- docs:reference/config-api/kubeadm-config.v1beta3.md, docs:reference/config-api/kubeadm-config.v1beta4.md
- docs:reference/networking/ports-and-protocols.md
- docs:reference/command-line-tools-reference/feature-gates/InPlacePodVerticalScaling.md
- blog:_posts/2025/kubelet-config-drop-in-directory-ga.md
