---
name: kubernetes-admin
description: Kubernetes cluster administration skill — cluster lifecycle, upgrades, RBAC, node drain and cordon, network policy, StorageClass and storage, observability, capacity, and troubleshooting. Load automatically for cluster-operations tasks.
invocation_policy: automatic
---

# Kubernetes Admin Skill Assembly

Unified Kubernetes cluster-administration knowledge base organized by domain features. Route to the correct feature file based on the task. All content targets Kubernetes v1.36 (GA); v1.37 items appear only as labeled **FUTURE** callouts.

## Configuration

The kubernetes-admin skill directory is the directory containing this file. Feature files are in the `features/` subdirectory.

## Capabilities

### Cluster Lifecycle
When installing, upgrading, draining, or maintaining cluster nodes:
1. Load `features/cluster-lifecycle.md` for kubeadm init/join/upgrade, node drain/cordon, version skew, and kubelet/control-plane maintenance

### RBAC
When designing Roles/Bindings, applying least privilege, or reviewing access:
1. Load `features/rbac.md` for Role/ClusterRole/Binding design, service accounts, and RBAC review

### Networking
When configuring CNI, Services/Ingress/Gateway API, NetworkPolicies, or DNS:
1. Load `features/networking.md` for Service types, Ingress/Gateway API, NetworkPolicies, DNS, and connectivity troubleshooting

### Storage
When managing StorageClasses, PV/PVC lifecycle, CSI, or snapshots:
1. Load `features/storage.md` for StorageClass defaults, PV/PVC lifecycle, CSI, VolumeSnapshots, and data protection

### Security
When enforcing admission policy, hardening the cluster, or handling secrets:
1. Load `features/security.md` for Pod Security Admission, admission controllers, secrets, image signing, and cluster hardening

### Observability
When inspecting metrics, logs, events, or audit data:
1. Load `features/observability.md` for metrics, logging, events, kube-state-metrics, monitoring/alerting, and audit

### API Migrations
When migrating off deprecated APIs or planning a control-plane upgrade:
1. Load `features/api-migrations.md` for the v1.36 deprecation/removal tables and admin-scoped migration guidance

### Troubleshooting
When diagnosing control plane, kubelet, etcd, or node/pod failures:
1. Load `features/troubleshooting.md` for etcd, kubelet, control plane, and node/pod failure diagnosis

### Capacity & Scheduling
When setting quotas, ranges, autoscaling, priority classes, or taints/tolerations:
1. Load `features/capacity-scheduling.md` for ResourceQuotas, LimitRanges, HPA/VPA, priority classes, taints/tolerations, and scheduling

## Cross-Referencing

When a task spans multiple domains, load the primary feature first, then additional features as needed. Features reference each other for cross-cutting topics; within-skill references use bare feature names. Cross-skill references to the kubernetes-developer skill use relative paths from this skill's root directory and appear in the feature files.
