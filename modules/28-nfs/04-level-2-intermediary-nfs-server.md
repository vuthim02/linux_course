## ⭐ Level 2: Intermediary — NFS Server and Client Configuration

![NFS Server-Client Architecture](https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Client-server_model.svg/220px-Client-server_model.svg.png)  
*NFS follows a client-server model. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Set up an NFS server with /etc/exports configuration, mount shares on clients with optimal options, configure autofs for on-demand mounting, apply security settings (root_squash, sec=krb5), and troubleshoot common issues using rpcinfo, showmount, and nfsstat.

### What You'll Cover
- `/etc/exports` syntax: host specifications, options, and wildcards
- Client-side mounting with `mount -t nfs` and `/etc/fstab` entries
- Security: `root_squash`, `no_all_squash`, `all_squash`, and Kerberos (`sec=krb5`)
- Autofs for on-demand mounting — auto.master and auto NFS maps
- Monitoring with `nfsstat`, `nfsiostat`, and `rpcinfo`
- Common failures: stale mounts, permission denied, portmapper issues

This is where NFS goes from concept to production. Proper export configuration and security settings prevent data exposure and service outages.

At this level you will practice:

- **`/etc/exports`**: `/shared 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)` shares `/shared` to the subnet. `rw` allows writes, `sync` writes to disk before replying, `no_subtree_check` avoids inode lookups, `no_root_squash` lets root on the client remain root.
- **Client mounting**: `mount -t nfs4 server:/shared /mnt/nfs` mounts via NFSv4. For persistent mounts, add to `/etc/fstab`: `server:/shared /mnt/nfs nfs4 defaults,_netdev 0 0`. The `_netdev` flag delays mounting until the network is up.
- **Security**: `root_squash` (default) maps root to `nobody`. `all_squash` maps all users to `anonymous`. `sec=krb5` uses Kerberos authentication. Without Kerberos, NFS relies on client-reported UIDs — a root user on any client can become any UID.
- **Autofs**: Maps in `/etc/auto.master.d/` trigger mounting only when a directory is accessed. `+/etc/auto.nfs` with `* -rw server:/shared/&` auto-mounts subdirectories. This prevents stale mounts and reduces boot-time delays.
- **Troubleshooting**: `nfsstat -c` shows client-side stats. `nfsiostat` shows per-mount I/O. Common issues: firewall blocking port 2049, `rpcbind` not running, stale file handles after server reboot, and UID mismatches.


[← Previous](03-section-1-what-is-nfs.md) | [↑ Index](index.md) | [Next →](05-section-2-nfs-server-setup.md)
