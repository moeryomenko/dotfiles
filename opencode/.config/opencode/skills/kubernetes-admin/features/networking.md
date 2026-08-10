# Networking — CNI, Services, Ingress/Gateway API, NetworkPolicies, DNS

> Networking is predictable when the CNI is installed first, Services are matched to the right type, and NetworkPolicy isolation is declared explicitly per direction.

## Rules

1. Install a CNI-compliant network plugin; the plugin assigns pod IPs, and the kube-apiserver, kubelet, and cloud-controller-manager must agree on IPv4/IPv6 allocation. Why: without a plugin pod networking simply does not exist.
2. Choose the Service type deliberately; `ClusterIP` is the default, `NodePort` and `LoadBalancer` build on it, and `ExternalName` is a DNS alias with no selectors or endpoints (see Decision Table). Why: the type fixes the exposure model and load-balancer behavior.
3. Treat the NodePort default range 30000-32767 as two bands (static and dynamic) to avoid port collisions. Why: random and fixed NodePorts can otherwise land on the same port.
4. Set `spec.allocateLoadBalancerNodePorts: false` when the LoadBalancer implementation routes directly to pods; the default is `true`. Why: skipping NodePort allocation avoids the port-range requirement for direct-routing LBs.
5. Set `.spec.loadBalancerClass` only on `type: LoadBalancer` Services. Why: the API rejects it on other types.
6. Migrate Services off `.spec.externalIPs`; it is deprecated in v1.36 with removal planned v1.43. Why: Kubernetes does not manage externalIP allocation and the field is on a deprecation path.
7. Use EndpointSlices (`discovery.k8s.io/v1`) instead of the Endpoints API, which has been deprecated since v1.33. Why: Endpoints breaks dual-stack and truncates large endpoint sets.
8. Set `pathType` on every Ingress path (`Prefix`, `Exact`, `ImplementationSpecific`), use `ingressClassName` to select an IngressClass, and set `.spec.defaultBackend` when no rules are present. Why: missing `pathType` fails validation and omitting `ingressClassName` relies on a default IngressClass (at most one default allowed).
9. Treat Gateway API as a family of custom-resource kinds (GatewayClass, Gateway, HTTPRoute, GRPCRoute) with `gateway.networking.k8s.io/v1` examples; the CRDs are an add-on. Do not claim a specific Gateway API release number; the exact release (v1.3-v1.6 era) is **UNVERIFIED** and depends on the controller's docs.
10. Remember pods are non-isolated by default; a pod becomes isolated for a direction only when a NetworkPolicy selecting it lists that direction in `policyTypes`. Why: a default-deny requires an explicit NetworkPolicy with empty rule lists.
11. Combine NetworkPolicy rules additively; a connection must be allowed by both the source's egress policy and the destination's ingress policy. Why: allow rules do not conflict, they union.
12. Verify a NetworkPolicy-enforcing plugin is installed; a policy with no implementing controller has no effect. Why: enforcement is CNI-plugin-specific.
13. Set the pod `dnsPolicy` correctly: `ClusterFirst` is the default, `ClusterFirstWithHostNet` is required for hostNetwork pods, and `None` disables cluster DNS and requires `dnsConfig`. Why: hostNetwork pods with `ClusterFirst` silently fall back to `Default`.
14. Stay within DNS search-list limits: up to 32 search domains and 2048 total characters. Why: exceeding the limits breaks name resolution.
15. Expect CoreDNS as the cluster DNS in kubeadm-managed clusters.

## Good / Bad Examples

Good:
```
kubectl get svc
kubectl get ingress
kubectl describe ingress test-ingress
```
Bad: relying on `kubectl expose deployment <name> --port=80 --type=NodePort` without checking the generated kubectl reference — the exact `kubectl expose` flags are **UNVERIFIED** in the doc tree and must be verified against the v1.36 kubectl reference before use.

Good (default-deny ingress):
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-ingress
spec:
  podSelector: {}
  policyTypes: ["Ingress"]
```
Bad (the classic "I thought it was deny-all"):
```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: not-deny-all
spec:
  podSelector: {}
  policyTypes: ["Egress"]     # ingress stays wide open
  egress:
  - {}
```

## Command Recipes

- Get Service/Ingress: `kubectl get svc`, `kubectl get ingress`, `kubectl describe ingress test-ingress` (docs:concepts/services-networking/ingress.md:166,404,435)
- Apply a NetworkPolicy: `kubectl apply -f network-policy.yaml` (docs:tasks/administer-cluster/declare-network-policy.md)
- Inspect cluster DNS from a pod: `kubectl exec -it dns-example -- cat /etc/resolv.conf` (docs:concepts/services-networking/dns-pod-service.md:346)
- List policy resources: `kubectl get networkpolicy` (docs:concepts/services-networking/network-policies.md:97-102)
- Full DNS resolution debugging: follow the workflow in docs:tasks/administer-cluster/dns-debugging-resolution.md

## Decision Table

| Service type | Behavior | Typical use |
|---|---|---|
| ClusterIP | stable virtual IP reachable only inside the cluster | internal workloads, the default |
| NodePort | static port on every node, built on ClusterIP | node-address access and manual load balancing |
| LoadBalancer | cloud controller provisions an LB, built on NodePort by default | internet-facing workloads on a cloud |
| ExternalName | DNS alias to an external name; no selectors/endpoints | pointing at external services |

## Version Notes

- Service `.spec.externalIPs` deprecated in v1.36 (docs:concepts/services-networking/service.md:1028-1030; blog:_posts/2026/kubernetes-v1-36-release/index.md:568-579).
- Endpoints API deprecated since v1.33; EndpointSlices are the replacement (docs:concepts/services-networking/service.md:312).
- Service `.spec.loadBalancerIP` deprecated since v1.24 (docs:concepts/services-networking/service.md:616).
- Gateway API exact release number is **UNVERIFIED** in the doc tree; blog coverage spans Gateway API v1.3-v1.6, so verify against the controller's docs before stating a version (docs:concepts/services-networking/gateway.md).
- **FUTURE (v1.37)**: kube-proxy `ipvs` mode still relies on `iptables` underneath; the project notes ipvs mode will not replace iptables (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md:38).

## Pitfalls

- Creating a NetworkPolicy with `policyTypes: [Egress]` only leaves ingress unrestricted — a default-deny requires explicit `policyTypes` with empty rule lists.
- Creating a NetworkPolicy without an enforcing plugin silently has no effect.
- Forgetting `pathType` on an Ingress path fails validation.
- Multiple default IngressClasses make `ingressClassName`-less Ingresses ambiguous; none being marked default means no class is applied.
- Relying on the deprecated Endpoints API breaks dual-stack Services and large-scale endpoint sets.

## Cross-References

- For app-side Service/Ingress/DNS usage and app-scoped NetworkPolicies: `../kubernetes-developer/features/services-networking.md`

## Doc Refs

- docs:concepts/cluster-administration/networking.md
- docs:concepts/services-networking/service.md
- docs:concepts/services-networking/service-traffic-policy.md
- docs:concepts/services-networking/ingress.md
- docs:concepts/services-networking/gateway.md
- docs:concepts/services-networking/network-policies.md
- docs:concepts/services-networking/dns-pod-service.md
- docs:concepts/services-networking/endpoint-slices.md
- docs:tasks/administer-cluster/declare-network-policy.md
- docs:tasks/administer-cluster/coredns.md
- docs:tasks/administer-cluster/dns-debugging-resolution.md
- docs:tasks/administer-cluster/network-policy-provider/_index.md
- docs:reference/networking/ports-and-protocols.md
