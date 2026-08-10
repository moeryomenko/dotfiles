# Security — Pod Security Admission, admission controllers, secrets, image signing, hardening

> Security is effective when admission rejects violations at creation time, secrets are encrypted at rest, and images are verified at deploy time.

## Rules

1. Enforce Pod Security Standards with Pod Security Admission (PSA), a built-in admission controller with three levels: `privileged`, `baseline`, `restricted` (see Decision Table). Why: `restricted` is the current hardening best practice.
2. Configure PSA per namespace with labels `pod-security.kubernetes.io/<MODE>: <LEVEL>` for modes `enforce`, `audit`, `warn`, plus an optional `<MODE>-version`. Why: `enforce` rejects, while `audit` and `warn` surface violations without blocking.
3. Add PSA exemptions only by username, runtimeClassName, or namespace, enumerated in the admission controller configuration. Why: a username exemption covers direct pod creation only, not workload resources the user creates.
4. Audit the default-enabled admission plugins before toggling any with `--enable-admission-plugins` / `--disable-admission-plugins`; the default list includes `PodSecurity`, `NodeRestriction`, `ResourceQuota`, and others. Why: disabling plugins without checking the list silently weakens the API server.
5. Treat Secrets as base64-encoded, **not** encrypted; they are stored unencrypted in etcd by default. Why: base64 is not encryption, so anyone with API or etcd access can read them.
6. Configure encryption at rest with `--encryption-provider-config` using `identity`, `aescbc`, `aesgcm`, `secretbox`, `kms` v1 (deprecated since v1.28), or `kms` v2. Why: kms v2 is current; v1 keeps a deprecated, slower provider in use.
7. Harden the cluster baseline: TLS for all API traffic, RBAC enabled, etcd access restricted (write access to etcd is close to root on the cluster), audit logging enabled, and data encrypted at rest. Why: each item closes a standard attack path.
8. Enable `RuntimeDefault` as the default seccomp profile for all workloads (possible since v1.27). Why: an unconfined container lacks the kernel hardening every other workload gets.
9. Reference images by sha256 digest or verify signatures at deploy time via admission control; avoid `latest` tags and run containers as an unprivileged user. Why: verifying only at build time leaves the supply-chain gap the docs call out.
10. Verify control plane image signatures with sigstore/cosign keyless signing using `cosign verify` and `cosign verify-blob`. Why: keyless signing ties signatures to identities without long-lived keys, and the exact `cosign` flags beyond the docs' example are **UNVERIFIED** — confirm them before scripting.

## Good / Bad Examples

Good:
```
kubectl label --dry-run=server -n my-namespace \
  pod-security.kubernetes.io/enforce=baseline \
  pod-security.kubernetes.io/warn=restricted
```
Bad: running PSA `enforce` on a namespace that already has violating workloads and expecting remediation — existing pods are not retroactively removed, only new pods are rejected.

Good:
```
kubectl create secret generic empty-secret
```
Bad: treating base64 "encoding" as encryption — a Secret's `data` is readable by anyone with API/etcd access.

## Command Recipes

- Enforce PSA on a namespace: `kubectl label --dry-run=server -n my-namespace pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/warn=restricted` (docs:concepts/security/pod-security-admission.md:66-75; task at docs:tasks/configure-pod-container/enforce-standards-namespace-labels.md)
- Create secrets: `kubectl create secret generic empty-secret`; `kubectl create secret docker-registry secret-tiger-docker --docker-username=... --docker-password=... --docker-email=...` (docs:concepts/configuration/secret.md:172,273-280)
- Inspect secret data (decodes base64): `kubectl get secret secret-tiger-docker -o jsonpath='{.data.*}' | base64 -d` (docs:concepts/configuration/secret.md:286)
- Verify a signed control plane image: `cosign verify registry.k8s.io/kube-apiserver-amd64:v1.36.x --certificate-identity ...` — exact identity flags are **UNVERIFIED** beyond the docs' example (docs:tasks/administer-cluster/verify-signed-artifacts.md:70)
- List enabled admission plugins: `kube-apiserver -h | grep enable-admission-plugins` (docs:reference/access-authn-authz/admission-controllers.md:124)

## Decision Table

| PSA level | Allows | Typical use |
|---|---|---|
| privileged | unrestricted (any privilege, host access) | system components, host networking, privileged daemons |
| baseline | minimal privilege prevention; blocks known escalations | default for most namespaces |
| restricted | current hardening best practices (drop all caps, non-root, seccomp set) | the target for production workloads |

## Version Notes

- PSA replaced PodSecurityPolicy, which was removed in v1.25 (docs:concepts/security/pod-security-admission.md:22; docs:reference/using-api/deprecation-guide.md:148-156).
- `kms` v1 encryption provider deprecated since v1.28; v2 is current (docs:tasks/administer-cluster/encrypt-data.md:260,278).
- `RuntimeDefault` seccomp defaulting is available since v1.27 (docs:concepts/security/security-checklist.md:165-166).
- User namespaces for pods (`UserNamespacesSupport`) is **GA** in v1.36, default true, locked (docs:reference/command-line-tools-reference/feature-gates/UserNamespacesSupport.md:19-22).
- `MutatingAdmissionPolicy` (CEL-based mutation admission) is **GA** in v1.36 (docs:reference/command-line-tools-reference/feature-gates/MutatingAdmissionPolicy.md:18-21).
- `ProcMountType` is **GA** in v1.36, default true, locked (docs:reference/command-line-tools-reference/feature-gates/ProcMountType.md:20-23).
- **FUTURE (v1.37)**: static pods referencing Secrets/ConfigMaps via `configMapRef`/`secretRef` will be prohibited; the `PreventStaticPodAPIReferences` gate is removed (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md:32).

## Pitfalls

- Using base64 "encoding" as if it were encryption — anyone with API or etcd access can read Secret data.
- Running PSA `enforce` on a namespace that already has violating workloads — existing pods are not retroactively removed, only new pods are rejected.
- Exempting usernames from PSA exempts only direct pod creation, not workload resources created by that user.
- Disabling admission plugins without checking the default list can silently weaken the API server (e.g., dropping `PodSecurity` or `NodeRestriction`).
- Leaving `kms` v1 configured when v2 is available keeps a deprecated, slower provider in use.
- Verifying image signatures only at build time, not at deploy time, leaves the supply-chain gap the docs explicitly call out.

## Doc Refs

- docs:concepts/security/pod-security-admission.md
- docs:concepts/security/pod-security-standards.md
- docs:reference/access-authn-authz/admission-controllers.md
- docs:concepts/configuration/secret.md
- docs:concepts/security/secrets-good-practices.md
- docs:tasks/administer-cluster/securing-a-cluster.md
- docs:concepts/security/security-checklist.md
- docs:concepts/security/hardening-guide/authentication-mechanisms.md
- docs:tasks/administer-cluster/encrypt-data.md
- docs:tasks/administer-cluster/kms-provider.md
- docs:tasks/administer-cluster/verify-signed-artifacts.md
- docs:tasks/configure-pod-container/enforce-standards-namespace-labels.md
- docs:tasks/configure-pod-container/enforce-standards-admission-controller.md
- docs:reference/command-line-tools-reference/feature-gates/UserNamespacesSupport.md
- docs:reference/command-line-tools-reference/feature-gates/MutatingAdmissionPolicy.md
- docs:reference/command-line-tools-reference/feature-gates/ProcMountType.md
