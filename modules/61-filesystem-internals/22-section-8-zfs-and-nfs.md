## Section 8: ZFS and NFS Internals

### ZFS — Advanced Volume Manager + Filesystem

ZFS combines a volume manager, RAID controller, and filesystem into one.

```bash
# Create a pool
zpool create -f tank /dev/sdb /dev/sdc
zpool create tank mirror /dev/sdb /dev/sdc  # RAID10-like

# Filesystem management
zfs create tank/data
zfs set compression=lz4 tank/data
zfs set mountpoint=/data tank/data

# Snapshots
zfs snapshot tank/data@$(date +%Y%m%d)
zfs rollback tank/data@20240701
zfs send tank/data@yesterday | zfs receive backup/data

# Pool health
zpool status
zpool iostat -v 1
```

### NFS Internals — Under the Hood

```bash
# NFS versions
# v3 — stateless, over UDP/TCP
# v4 — stateful, compound RPC, pseudo-fs
# v4.1 — pNFS (parallel NFS)

# Mount internals
mount -t nfs -o vers=4.2,noatime,hard,intr \
  10.0.0.1:/export /mnt

# Debug NFS
rpcdebug -m nfs -s all      # Enable NFS debug
cat /proc/net/rpc/nfsd      # Server stats
nfsstat -c                   # Client stats
```

| Feature | ZFS | NFS (network) |
|---------|-----|---------------|
| Scope | Local FS + volume mgmt | Network file sharing |
| Data integrity | Checksums all data + metadata | Depends on transport |
| Snapshots | Native, instant | N/A (use LVM/ZFS on server) |
| Compression | Built-in (lz4, gzip, zstd) | N/A |
| Dedup | Built-in | N/A |
| RAID | Built-in (mirror, raidz) | N/A |
