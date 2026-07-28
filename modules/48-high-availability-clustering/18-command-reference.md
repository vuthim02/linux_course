## 📋 Command Reference

| Command | Purpose |
|---------|---------|
| `crm status` | Show cluster status |
| `crm_mon -1 -r -f` | Real-time cluster monitor |
| `crm configure show` | Show full XML config |
| `crm configure primitive ...` | Create a resource |
| `crm configure group ...` | Create a resource group |
| `crm configure clone ...` | Create a cloned resource |
| `crm configure ms ...` | Create multi-state resource |
| `crm configure colocation ...` | Create colocation constraint |
| `crm configure order ...` | Create ordering constraint |
| `crm configure location ...` | Create location constraint |
| `crm resource move <rsc> <node>` | Move resource to node |
| `crm resource ban <rsc> <node>` | Ban resource from node |
| `crm node standby <node>` | Put node in standby |
| `crm node online <node>` | Bring node back online |
| `corosync-cmapctl` | Show Corosync cluster map |
| `corosync-quorumtool -p` | Show quorum status |
| `corosync-cfgtool -s` | Show Corosync transport status |
| `stonith_admin --reboot <node>` | Reboot node via fencing |
| `drbdadm create-md <res>` | Create DRBD metadata |
| `drbdadm up <res>` | Activate DRBD resource |
| `drbdadm down <res>` | Deactivate DRBD resource |
| `drbdadm primary <res>` | Set DRBD to primary |
| `drbdadm secondary <res>` | Set DRBD to secondary |
| `drbdadm status` | Show DRBD status |
| `cat /proc/drbd` | Detailed DRBD status |
| `mkfs.gfs2 -p lock_dlm -j 2 -t <cluster>:<data> <dev>` | Create GFS2 filesystem |
| `ipvsadm -L -n` | Show LVS table |
| `keepalived -t` | Test Keepalived config syntax |
| `journalctl -u keepalived -f` | Follow Keepalived logs |
| `pcs resource create` | Create resource (RHEL style) |
| `pcs cluster setup` | Set up cluster (RHEL style) |





[← Previous](17-deep-understanding.md) | [↑ Index](index.md) | [Next →](19-whats-coming-in-part-49.md)
