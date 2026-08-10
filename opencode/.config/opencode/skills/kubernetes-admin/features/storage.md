# Storage — StorageClasses, PV/PVC lifecycle, CSI, snapshots, data protection

> Storage is safe when reclaim policy matches the data's value, default classes are unambiguous, and snapshots are taken only where CSI is installed.

## Rules

1. Define StorageClass with `provisioner`, `parameters`, and `reclaimPolicy`; the default `reclaimPolicy` is `Delete` when unset. Why: `Delete` destroys backing storage on PVC deletion, so set `Retain` for precious data.
2. Mark exactly one default StorageClass with `storageclass.kubernetes.io/is-default-class: "true"`; when multiple defaults exist, the most recently created one is used. Why: multiple defaults make class selection nondeterministic.
3. Leave `storageClassName` unset on a PVC to use the default class; set `storageClassName: ""` to disable defaulting (binds only to static PVs or fails). Why: with no default class, an unset field leaves the PVC Pending forever.
4. Choose `volumeBindingMode`: unset defaults to `Immediate`; `WaitForFirstConsumer` delays binding/provisioning until a pod using the PVC is scheduled.
5. Set `allowVolumeExpansion: true` to enable PVC size expansion.
6. Use access modes deliberately: `ReadWriteOnce` (RWO), `ReadOnlyMany` (ROX), `ReadWriteMany` (RWX), `ReadWriteOncePod` (RWOP). Why: RWOP is GA since v1.29 and supported only by CSI.
7. Pick `volumeMode`: `Filesystem` (default) or `Block`. Why: block mode changes how the volume is presented to the container.
8. Grow PVCs by editing `.spec.resources.requests.storage` upward only; the new value must stay above `.status.capacity`. Why: shrinking is unsupported and attempts below current size fail.
9. Use VolumeSnapshots (`snapshot.storage.k8s.io/v1`) for point-in-time copies; they are **CSI drivers only** and require the snapshot controller plus the csi-snapshotter sidecar deployed. Why: without CSI and the sidecar, no snapshot is taken.
10. Honor `deletionPolicy` on VolumeSnapshot: `Delete` removes the backing snapshot and content; `Retain` keeps them.
11. Keep VolumeSnapshotClass immutable (`driver`, `deletionPolicy`, `parameters`); one default class per CSI driver is selected when the VolumeSnapshot omits the class.
12. Migrate off in-tree storage drivers to CSI; `awsElasticBlockStore` was removed in v1.27, while `gcePersistentDisk` and `portworxVolume` are deprecated in this tree. Why: CSI is the supported storage path and in-tree drivers keep being removed.
13. Do not use the `gitRepo` volume source; it is disabled (removed) as of v1.36. Why: it was removed from kubelet and cannot be re-enabled — see features/api-migrations.md.
14. Back up etcd regularly and run a five-member etcd cluster for HA. Why: etcd is the backing store for all cluster state.

## Good / Bad Examples

Good:
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
reclaimPolicy: Retain
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```
Bad:
```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"   # second default class
provisioner: ebs.csi.aws.com
reclaimPolicy: Delete    # destroys the volume when the PVC is deleted
```
With a second default class present, selection is nondeterministic (most recently created wins).

## Command Recipes

- List/describe: `kubectl get pv`, `kubectl get pvc`, `kubectl describe pvc <name>` (docs:tasks/administer-cluster/change-pv-reclaim-policy.md:41-43)
- Change PV reclaim policy: `kubectl patch pv <your-pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'` (docs:tasks/administer-cluster/change-pv-reclaim-policy.md:52)
- Change the default StorageClass: `kubectl patch storageclass <name> -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'` (docs:tasks/administer-cluster/change-default-storage-class.md)
- Resize a PVC: `kubectl edit pvc <name>` and increase `spec.resources.requests.storage` (requires `allowVolumeExpansion`) (docs:concepts/storage/persistent-volumes.md:485-492)
- Change access mode to RWOP (RWO only): `kubectl patch pv <pv> -p '{"spec":{"accessModes":["ReadWriteOncePod"]}}'` (docs:tasks/administer-cluster/change-pv-access-mode-readwriteoncepod.md:53,82)

## Decision Table

| Reclaim policy | Behavior on PVC deletion | Data safety |
|---|---|---|
| Retain | PV and backing storage remain; manual reclamation required | safe — no automatic deletion |
| Delete | PV and backing storage are removed (default for dynamically provisioned PVs) | data loss — the common incident |
| Recycle | deprecated; use dynamic provisioning instead | do not use |

## Version Notes

- VolumeSnapshots API `snapshot.storage.k8s.io/v1` is stable; support is restricted to CSI (docs:concepts/storage/volume-snapshots.md:48-51).
- VolumeGroupSnapshot graduated to GA in v1.36 (blog:_posts/2026/kubernetes-v1-36-release/index.md:560).
- `ReadWriteOncePod` is GA since v1.29 and CSI-only (docs:tasks/administer-cluster/change-pv-access-mode-readwriteoncepod.md:18,25).
- The `Recycle` reclaim policy is deprecated (docs:concepts/storage/persistent-volumes.md:215).
- In-tree storage drivers continue to be removed (`awsElasticBlockStore` removed v1.27; `gcePersistentDisk` and `portworxVolume` marked deprecated in this tree) — migration to CSI is the admin action (docs:concepts/storage/volume-snapshots.md:241-242; docs:concepts/storage/volumes.md:253,723-725).
- **FUTURE (v1.37)**: SELinuxMount (SELinux volume relabeling) is expected to reach GA and default on; it affects volume relabeling behavior with no effect without SELinux (blog:_posts/2026/kubernetes-v1-37-sneak-peek.md:69-78).

## Pitfalls

- Deleting a PVC bound to a `Delete`-reclaim PV destroys the backing storage — a common data-loss incident; set `Retain` for precious data.
- Leaving `storageClassName` unset when no default class exists leaves PVCs Pending forever.
- Creating two default StorageClasses makes class selection nondeterministic (most recently created wins).
- Attempting a VolumeSnapshot without CSI or without the snapshot-controller/sidecar results in no snapshot being taken.
- Trying to shrink a PVC is unsupported; expansion attempts below current size fail.
- RWOP access mode requires CSI; unsupported volume plugins reject it.

## Doc Refs

- docs:concepts/storage/storage-classes.md
- docs:concepts/storage/persistent-volumes.md
- docs:concepts/storage/dynamic-provisioning.md
- docs:concepts/storage/volume-snapshots.md
- docs:concepts/storage/volume-snapshot-classes.md
- docs:concepts/storage/volumes.md
- docs:tasks/administer-cluster/change-default-storage-class.md
- docs:tasks/administer-cluster/change-pv-reclaim-policy.md
- docs:tasks/administer-cluster/change-pv-access-mode-readwriteoncepod.md
- docs:tasks/administer-cluster/limit-storage-consumption.md
- docs:tasks/administer-cluster/configure-upgrade-etcd.md
- blog:_posts/2026/kubernetes-v1-36-release/index.md
