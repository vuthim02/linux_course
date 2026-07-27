## 🔍 Section 4: NFSv4 Features

### The Pseudo-Filesystem

NFSv4 introduces the concept of a **pseudo-filesystem** — the server presents a single unified namespace, starting at the root `/` of the NFSv4 tree:

```bash
# On the server, you export multiple directories:
/export/data       *(rw)
/export/home       *(rw)
/export/backups    *(ro)

# With NFSv4, clients can see them all under the pseudo-root:
mount -t nfs4 server:/ /mnt/nfs4
ls /mnt/nfs4/
# data/  home/  backups/

# The pseudo-filesystem is NOT real — it's a virtual view
# It's defined by the server's NFSv4 "fsid" configuration

# Export with fsid=0 to mark the root:
/export  *(rw,fsid=0,no_subtree_check)
/export/data  *(rw,no_subtree_check)
/export/home  *(rw,no_subtree_check)
```

### ID Mapping — idmapd

NFSv4 uses string-based user/group identifiers (user@domain) instead of numeric UID/GIDs:

```bash
# /etc/idmapd.conf
[General]

# The domain MUST match on client and server
Domain = example.com

[Mapping]
Nobody-User = nobody
Nobody-Group = nogroup

# Restart after changes
sudo systemctl restart nfs-idmapd
```

**How ID mapping works:**
```
Server: uid=1000 (alice)  →  "alice@example.com"  →  sent over NFSv4
Client: receives "alice@example.com"  →  looks up local user  →  uid=1000
```

If domains don't match, all files appear owned by `nobody`.

```bash
# Check idmapd status
sudo systemctl status nfs-idmapd

# Debug idmapd
sudo rpc.idmapd -f -vvv
```

### Kerberos Authentication (sec=krb5)

NFSv4 supports Kerberos for strong authentication:

| Security Flavor | Description |
|----------------|-------------|
| `sec=sys` | Default — AUTH_SYS (trusts client's UID/GID claims) |
| `sec=krb5` | Kerberos authentication only |
| `sec=krb5i` | Kerberos authentication + integrity checking |
| `sec=krb5p` | Kerberos authentication + integrity + privacy (encryption) |

```bash
# Server: /etc/exports with Kerberos
/export/secure  *(rw,sec=krb5p)

# Client mount
sudo mount -t nfs4 -o sec=krb5p server:/export/secure /mnt/secure
```

**Kerberos setup (high-level):**
```bash
# 1. Install Kerberos packages
sudo apt install -y krb5-user krb5-config

# 2. Create NFS service principal
# On KDC:
kadmin.local -q "addprinc -randkey nfs/server.example.com"

# 3. Export keytab
kadmin.local -q "ktadd -k /etc/krb5.keytab nfs/server.example.com"

# 4. Set up /etc/exports with sec=krb5
/export/secure  *(rw,sec=krb5p)

# 5. On client, mount with Kerberos
kinit user@EXAMPLE.COM
sudo mount -t nfs4 -o sec=krb5p server:/export/secure /mnt/secure
```

### NFSv4 ACLs

NFSv4 supports rich ACLs (more granular than POSIX):

```bash
# View NFSv4 ACL
nfs4_getfacl /mnt/nfs4/file.txt

# Set NFSv4 ACL
nfs4_setfacl -a A::1000:RW /mnt/nfs4/file.txt  # Add RW for user 1000
nfs4_setfacl -a A:g:1001:RX /mnt/nfs4/file.txt  # Add RX for group 1001

# Remove ACL
nfs4_setfacl -x A::1000:RW /mnt/nfs4/file.txt
```

| ACL Permission | Meaning |
|----------------|---------|
| `R` | Read data |
| `W` | Write data |
| `X` | Execute |
| `D` | Delete |
| `a` | Append |
| `r` | Read attributes |
| `w` | Write attributes |
| `d` | Delete child |

### Compound RPC Operations

NFSv4 combines multiple operations into a single RPC:

```bash
# Instead of 4 RPC calls:
#   LOOKUP → OPEN → READ → CLOSE
# NFSv4 sends one compound:
#   PUTFH + OPEN + READ + CLOSE

# This dramatically reduces latency for metadata-heavy workloads
```

---



---

[← Previous](06-section-3-nfs-client-setup.md) | [↑ Index](index.md) | [Next →](08-level-3-advanced-performance-internals.md)
