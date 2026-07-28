## 🔍 Section 11: Locking in NFS

### NFSv3 — Separate Lock Daemons

NFSv3 uses **Network Lock Manager (NLM)** protocol, implemented by separate daemons:

```bash
# rpc.lockd — handles file locking
# rpc.statd — monitors server status for crash recovery

# On server:
sudo systemctl status nfs-lock    # lockd
sudo systemctl status nfs-statd   # statd

# Check that lock manager is registered
rpcinfo -p | grep nlockmgr
# 100021    1   tcp  41793  nlockmgr
# 100021    3   tcp  41793  nlockmgr
# 100021    4   tcp  41793  nlockmgr
```

**NFSv3 locking flow:**
```
1. Client A: LOCK(fh, range, type) via NLM
2. Server: checks if another client holds conflicting lock
3. If no conflict → grant lock, record state in rpc.statd
4. If conflict → deny or block (client can retry)
5. Client A: UNLOCK(fh, range) via NLM
```

**Crash recovery (NFSv3):**
```
1. Server crashes → all locks are lost
2. Server reboots → rpc.statd starts
3. Clients detect server reboot (SM_NOTIFY)
4. Clients re-establish locks via rpc.lockd
5. rpc.statd on client and server coordinate via /var/lib/nfs/statd/
```

### NFSv4 — Built-in Locking

NFSv4 integrates locking into the main protocol — no separate daemons:

```bash
# NFSv4 lock operations are part of the compound RPC:
# OPEN (with share access/deny modes)
# LOCK
# LOCKU (lock unlock)
# LOCKT (lock test)
# CLOSE

# NFSv4 uses LEASE-BASED locking:
# 1. Client requests lock
# 2. Server grants lock + sets a lease timer
# 3. Client sends RENEW before lease expires
# 4. If client doesn't renew → server revokes ALL client state

# Lease duration (default: 90 seconds)
cat /proc/fs/nfsd/lease_time
# Output: 90
```

### NFSv4 Delegations

A **delegation** gives a client exclusive control over a file:

```bash
# READ delegation:
#   Server guarantees no other client is writing
#   Client can cache reads without contacting server
#   Server RECALLS delegation if another client needs write access

# WRITE delegation:
#   Client can buffer writes locally
#   Server recalls before granting access to another client
#   Client flushes writes during recall

# Check delegations:
cat /proc/self/mountstats | grep "deleg"
#   delegations: current delegations held
#   delegations recalls: times server recalled delegations
```

### File Lock Commands

```bash
# Test locking with flock
flock /mnt/nfs/shared.lock -c "echo 'locked!'; sleep 10"

# Check locks on NFS mount
lslocks | grep NFS

# Check locks from server side
cat /proc/fs/nfsd/clients/*/states 2>/dev/null

# NFSv4 lock test
cat > /tmp/locktest.c << 'EOF'
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fd = open("/mnt/nfs/test.lock", O_RDWR | O_CREAT, 0644);
    struct flock fl = {F_WRLCK, SEEK_SET, 0, 0, 0};
    fl.l_pid = getpid();
    if (fcntl(fd, F_SETLK, &fl) == 0)
        printf("Lock acquired\n");
    else
        perror("Lock failed");
    close(fd);
    return 0;
}
EOF
gcc -o /tmp/locktest /tmp/locktest.c
/tmp/locktest
```

### Lock Compatibility Matrix

| Current \ Request | READ lock | WRITE lock |
|------------------|-----------|------------|
| None | Grant | Grant |
| READ lock | Grant | **Block** |
| WRITE lock | **Block** | **Block** |

### NFSv4 Lock Recovery

```bash
# On lock conflict or server reboot:
# 1. Client detects stale stateid (NFS4ERR_STALE_STATEID)
# 2. Client re-opens file
# 3. Client requests lock with reclaim flag
# 4. Server checks reclaim against /var/lib/nfs/v4recovery/

# Manual lock recovery (if automagic fails):
sudo umount /mnt/nfs
sudo mount -t nfs4 server:/export/data /mnt/nfs
```





[← Previous](14-section-10-nfs-vs-other.md) | [↑ Index](index.md) | [Next →](16-practice-section-15-hands-on-exercises.md)
