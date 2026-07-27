## 4. Mount Namespace

### chroot vs Mount Namespace

`chroot` changes the apparent root directory for one process and its children. Mount namespaces go much further — they isolate the entire mount table.

```
┌──────────────────────────────────────────────────────┐
│  chroot (limited isolation)                           │
│                                                       │
│  Process sees / as /new/root, but:                    │
│  - Other processes see the same mount table           │
│  - /proc, /sys still show host information            │
│  - Mount operations visible to other chrooted procs   │
│  - Can often be escaped                               │
│                                                       │
│  ─────────────────────────────────────────────────    │
│                                                       │
│  Mount Namespace (full isolation)                     │
│                                                       │
│  Complete independent mount table:                    │
│  - Private /proc, /sys, /dev                          │
│  - Mount/unmount invisible to other namespaces        │
│  - OverlayFS for container layers                     │
│  - tmpfs for /run, /tmp                               │
│  - Cannot be escaped without CAP_SYS_ADMIN            │
└──────────────────────────────────────────────────────┘
```

### Creating a Mount Namespace

```bash
# Create an isolated mount namespace with a private /proc
sudo unshare --mount --fork bash

# Verify isolation
mount | wc -l    # Fewer mounts than host
ls /proc         # Fresh /proc

# Mount something — invisible to host
mkdir /tmp/mnt
mount -t tmpfs tmpfs /tmp/mnt
echo "private" > /tmp/mnt/secret.txt

# From host terminal:
cat /tmp/mnt/secret.txt   # "No such file" — isolated!
```

### pivot_root vs chroot

Containers use `pivot_root` to change the root filesystem, not `chroot`. The difference matters:

```
chroot:
  - Changes root directory pointer
  - Old root still accessible if process has fd to it
  - Mount table shared with parent namespace
  - Can be escaped via open file descriptors

pivot_root:
  - Actually moves root mount to a new mount namespace
  - Old root becomes a regular mount that can be unmounted
  - Combined with mount namespace, provides full isolation
  - Used by runc/crun in every container startup
```

```bash
# Simulate what containers do at startup
mkdir -p /tmp/newroot
# (populate with rootfs content — in Docker this is the image layers)

sudo unshare --mount --fork bash

# Mount the new root
mount --bind /tmp/newroot /tmp/newroot

# pivot_root: move to new root, unmount old
cd /tmp/newroot
mkdir old_root
pivot_root . old_root

# Now we're in the new root
ls /
# bin  etc  lib  proc  sys  usr  var  old_root

# Unmount old root completely
umount -l /old_root
rm -rf /old_root

# The old host filesystem is gone
ls /old_root   # "No such file or directory"
```

> ⚠️ **Warning:** `pivot_root` requires `CAP_SYS_ADMIN` in the mount namespace. In user namespaces, this is available to unprivileged processes inside the namespace.

### Mount Propagation

Mount events can propagate between namespaces. The propagation type controls this:

```
┌────────────────────────────────────────────────────────┐
│  Mount Propagation Types                                │
├──────────────────────┬─────────────────────────────────┤
│  MS_PRIVATE          │ No propagation at all           │
│                      │ Changes are invisible           │
├──────────────────────┼─────────────────────────────────┤
│  MS_SHARED           │ Events propagate both ways      │
│                      │ Mount in A appears in B         │
├──────────────────────┼─────────────────────────────────┤
│  MS_SLAVE            │ One-way from master to slave    │
│                      │ Master changes appear in slave  │
│                      │ Slave changes are private       │
├──────────────────────┼─────────────────────────────────┤
│  MS_UNBINDABLE       │ Cannot be bind-mounted          │
│                      │ Private + unbindable            │
└──────────────────────┴─────────────────────────────────┘
```

```bash
# Check current propagation
cat /proc/self/mountinfo | grep " / "
# Look for shared/master/slave markers

# Docker makes container mounts private by default
# You can see this in container mountinfo:
cat /proc/<container_pid>/mountinfo | head -20

# Example output:
# 123 89 253:2 / / rw,relatime master:1 - ext4 /dev/vda1 rw
# 124 123 0:25 / /proc rw,nosuid,nodev,noexec,relatime - proc proc rw
# 125 123 0:26 / /sys rw,nosuid,nodev,noexec,relatime - sysfs sysfs rw
# 126 123 0:5 / /dev rw,nosuid - devtmpfs devtmpfs rw
```

---



---

[← Previous](04-3-network-namespace.md) | [↑ Index](index.md) | [Next →](06-5-uts-ipc-and-user.md)
