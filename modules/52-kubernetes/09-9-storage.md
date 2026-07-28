## 9. Storage

### Volume Types

**emptyDir** — ephemeral, created when pod starts, deleted when pod is removed.

```yaml
volumes:
- name: scratch
  emptyDir:
    sizeLimit: 1Gi     # optional, default unlimited
```

**hostPath** — mounts a file or directory from the host node's filesystem. Use sparingly (mostly for DaemonSets).

```yaml
volumes:
- name: varlog
  hostPath:
    path: /var/log
    type: DirectoryOrCreate   # Directory, File, Socket, CharDevice, etc.
```

### PersistentVolume and PersistentVolumeClaim

PVs are cluster resources (like nodes). PVCs are requests for storage (like pods).

**Static Provisioning** — admin creates PVs manually.

```yaml
# admin/pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs-1
spec:
  capacity:
    storage: 50Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain   # Retain, Delete, Recycle
  storageClassName: nfs
  nfs:
    server: nfs.example.com
    path: /exports/data
```

```yaml
# user/pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-claim
  namespace: production
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 20Gi
  storageClassName: nfs
```

```yaml
# pod using the PVC
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-claim
```

**Dynamic Provisioning** — PVC triggers automatic PV creation via a StorageClass.

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs       # depends on cloud
parameters:
  type: gp3
  fsType: ext4
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer  # or Immediate
allowVolumeExpansion: true
```

```yaml
# PVC that triggers dynamic provisioning
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-claim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
  storageClassName: fast-ssd
```

### PersistentVolumeClaim in a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-storage
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: persistent-storage
      mountPath: /data
  volumes:
  - name: persistent-storage
    persistentVolumeClaim:
      claimName: data-claim
```

### CSI Drivers

CSI (Container Storage Interface) allows any storage vendor to write a driver. Common CSI drivers:

- **AWS EBS**: `ebs.csi.aws.com`
- **GCP PD**: `pd.csi.storage.gke.io`
- **Azure Disk**: `disk.csi.azure.com`
- **NFS**: `nfs.csi.k8s.io`
- **Rook/Ceph**: `rook-ceph.rbd.csi.ceph.com`
- **Longhorn**: `driver.longhorn.io`

```bash
# Install AWS EBS CSI driver (via Helm)
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm upgrade --install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system
```





[← Previous](08-8-configmaps-and-secrets.md) | [↑ Index](index.md) | [Next →](10-10-rbac-role-based-access-control.md)
