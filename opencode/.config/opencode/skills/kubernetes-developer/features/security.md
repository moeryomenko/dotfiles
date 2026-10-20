# Security — app-level PSA compliance, seccomp, runAsNonRoot, image/secret handling, app NetworkPolicies

> Harden at the manifest level: meet the Pod Security Standard your namespace enforces, drop capabilities, run as non-root, and scope network access with app NetworkPolicies.

## Rules

1. Target a Pod Security Standard level per namespace: `privileged` (unrestricted), `baseline` (blocks known privilege escalations), `restricted` (current hardening best practices). Why: the three cumulative levels define the admission bar.
2. Meet restricted-policy requirements: drop ALL capabilities (only `NET_BIND_SERVICE` may be added back), `allowPrivilegeEscalation: false`, `runAsNonRoot: true` or an explicitly non-zero `runAsUser`, explicit `seccompProfile.type` `RuntimeDefault` or `Localhost` (Linux only), and volume types restricted to configMap/csi/downwardAPI/emptyDir/ephemeral/persistentVolumeClaim/projected/secret. Set both `runAsNonRoot: true` and an explicit non-zero UID when image-user metadata is unknown or untrusted. Why: restricted encodes the current hardening baseline.
3. Meet baseline-policy controls: no host namespaces (hostNetwork/hostPID/hostIPC), no privileged containers, capability additions limited to a known list, no hostPath, hostPorts disallowed/recommended-restricted, no `Unconfined` seccomp, safe sysctls only, AppArmor not below `RuntimeDefault`, and probe/lifecycle-hook `host` fields disallowed (v1.34+). Why: baseline blocks known privilege escalation without breaking common workloads.
4. Enforce levels with Pod Security Admission (stable since v1.25) via namespace labels `pod-security.kubernetes.io/<enforce|audit|warn>: <privileged|baseline|restricted>` and optional `<MODE>-version: <v1.36|latest>`. Why: `enforce` rejects violating Pods, `audit` logs, `warn` warns.
5. Remember enforce mode applies to Pods, not workload objects (audit/warn apply to workloads); exemptions exist for usernames, RuntimeClassNames, and namespaces. Why: admission evaluates Pods after controllers render them.
6. PodSecurityPolicy is removed — migrate to PSA or a 3rd-party webhook. Why: PSP was removed in v1.25.
7. Set seccomp explicitly: `securityContext.seccompProfile.type` with `RuntimeDefault`, `Unconfined`, or `Localhost` (`localhostProfile` only when `type: Localhost`; the localhost profile path is under the kubelet root dir). Why: restricted requires seccomp to be EXPLICITLY set.
8. A Pod with no `seccompProfile` fails restricted; container-level may be omitted only if pod-level is set (and vice versa). Why: restricted demands an explicit profile somewhere in scope.
9. Use `runAsNonRoot: true` with a non-root image USER; `runAsUser`/`runAsGroup`/`fsGroup`/`supplementalGroups` and `supplementalGroupsPolicy` (fine-grained control, requires a gate on kube-apiserver/kubelet) are documented in the security-context task. Why: runAsNonRoot plus a root-USER image prevents startup.
10. Add/drop capabilities via `securityContext.capabilities` using names WITHOUT the `CAP_` prefix (e.g. `SYS_TIME` for `CAP_SYS_TIME`). Why: manifest names omit the prefix; adding `CAP_NET_ADMIN` instead of `NET_ADMIN` fails or is ignored.
11. Enable user namespaces for Pods with `spec.hostUsers: false` (GA/locked in v1.36, `UserNamespacesSupport`); requires containerd 2.0+ or CRI-O 1.25+, and relaxes PSA seccomp/AppArmor/SELinux checks for user-namespaced Pods. Why: user namespaces isolate Pod uid 0 from the host.
12. Pull private images via `imagePullSecrets` with `kubernetes.io/dockercfg`/`kubernetes.io/dockerconfigjson` Secret types, created with `kubectl create secret docker-registry`. Why: the node's container runtime authenticates with the registry.
13. Handle Secrets safely: enable encryption at rest, least-privilege RBAC, restrict access per container, and consider external secret stores. Why: Secrets are unencrypted in etcd by default.
14. Apply app-side NetworkPolicies with default-deny patterns and allow DNS egress explicitly. Why: default-deny egress blocks name resolution.
15. `RuntimeDefault` AppArmor satisfies the PSS field requirement, but actual confinement depends on node kernel and runtime support; verify behavior on the target nodes. Why: PSS validation and node enforcement are distinct layers.
16. SELinux volume labeling behavior, including mount-option labeling and `seLinuxChangePolicy`, depends on the Kubernetes release, enabled features, and CSI-driver support. Verify the target driver and shared-volume behavior before relying on mount-based relabeling. Why: Pods with different SELinux labels can have incompatible volume-sharing requirements.

## Good / Bad Examples

Good (restricted-compliant):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
spec:
  securityContext:
    runAsNonRoot: true
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: app
      image: myapp:1.0
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: [ALL]
```
Bad (fails restricted — no explicit seccomp):
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: insecure-pod
spec:
  securityContext:
    runAsNonRoot: true      # no seccompProfile -> restricted rejects
  containers:
    - name: app
      image: myapp:1.0
```

Good (capability names without the prefix):
```yaml
securityContext:
  capabilities:
    add: [NET_ADMIN]
```
Bad:
```yaml
securityContext:
  capabilities:
    add: [CAP_NET_ADMIN]   # wrong: must omit the CAP_ prefix
```

Bad (runAsNonRoot with a root-USER image):
```yaml
spec:
  securityContext:
    runAsNonRoot: true
  containers:
    - name: app
      image: root-user-image:1.0   # image USER is root -> container fails to start
```

## Command Recipes

- Preview PSA enforcement on a Namespace: `kubectl label namespace <namespace> pod-security.kubernetes.io/enforce=restricted --dry-run=server`; omit `--dry-run=server` to apply, and use `--overwrite` only to deliberately replace an existing policy label (docs:tasks/configure-pod-container/enforce-standards-namespace-labels.md)
- Create a docker-registry Secret: `kubectl create secret docker-registry secret-tiger-docker --docker-username=<user> --docker-password=<pass> --docker-email=<email>` (docs:concepts/configuration/secret.md)
- Check a running container's capabilities: `kubectl exec <pod> -- grep Cap /proc/1/status` (docs:tasks/configure-pod-container/security-context.md)
- Inspect a debug profile's security context: `kubectl get pod myapp -o jsonpath='{.spec.ephemeralContainers[0].securityContext}'` (docs:tasks/debug/debug-application/debug-running-pod.md)

## Decision Tables

PSA level choice:

| Level | Blocks | Best for |
|---|---|---|
| privileged | nothing | system/CNI daemons, admin tooling |
| baseline | known privilege escalations | general workloads on legacy clusters |
| restricted | hardening best practices | new/default workloads, security-sensitive apps |

## Version Notes

- Pod Security Admission: stable since v1.25 (docs:concepts/security/pod-security-admission.md).
- User namespaces for Pods: GA/locked in v1.36 (`UserNamespacesSupport`) (docs:reference/command-line-tools-reference/feature-gates/UserNamespacesSupport.md; blog:_posts/2026/kubernetes-v1-36-release/index.md).
- SELinux volume mount-option labeling and `seLinuxChangePolicy` are release-, feature-, and CSI-driver-dependent; verify the target cluster and storage driver before enabling a shared-volume pattern (docs:tasks/configure-pod-container/security-context.md).
- External ServiceAccount token signing (KEP-740): GA in v1.36 (blog:_posts/2026/kubernetes-v1-36-release/index.md).

## Pitfalls

- Restricted PSA requires seccomp to be EXPLICITLY set — a Pod with no `seccompProfile` fails restricted; container-level may be omitted only if pod-level is set (and vice versa) (docs:concepts/security/pod-security-standards.md).
- `runAsNonRoot: true` with a container image whose USER is root causes the container to fail to start (docs:tasks/configure-pod-container/security-context.md; docs:concepts/security/pod-security-standards.md).
- Base64 is not encryption — Secret `data` is obscured only; anyone with API/etcd access can read it (docs:concepts/configuration/secret.md).
- Default-deny egress NetworkPolicy blocks DNS; allow TCP and UDP port 53 to the DNS workload labels/namespace actually used by the target cluster, then validate lookup behavior (docs:concepts/services-networking/network-policies.md).
- Capability names in manifests must omit `CAP_`; adding `CAP_NET_ADMIN` instead of `NET_ADMIN` fails or is ignored (docs:tasks/configure-pod-container/security-context.md).
- AppArmor `RuntimeDefault` meets the PSS field requirement, but effective confinement still depends on node/kernel/runtime support; validate it on target nodes (docs:tasks/configure-pod-container/security-context.md).

## Cross-References

- For NetworkPolicy semantics and DNS caveats: `features/services-networking.md`
- For Secret types and handling: `features/config-secrets.md`
- For user namespaces and securityContext in workloads: `features/workloads.md`

## Doc Refs

- docs:concepts/security/pod-security-standards.md
- docs:concepts/security/pod-security-admission.md
- docs:tasks/configure-pod-container/security-context.md
- docs:tasks/configure-pod-container/enforce-standards-namespace-labels.md
- docs:tasks/configure-pod-container/pull-image-private-registry.md
- docs:concepts/workloads/pods/user-namespaces.md
- docs:concepts/configuration/secret.md
- docs:concepts/security/secrets-good-practices.md
- docs:concepts/services-networking/network-policies.md
- blog:_posts/2026/kubernetes-v1-36-release/index.md
- blog:_posts/2026/breaking-changes-in-selinux-volume-labeling.md
