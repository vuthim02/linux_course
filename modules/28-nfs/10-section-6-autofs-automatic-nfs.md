## 🔍 Section 6: Autofs — Automatic NFS Mounting

### Why Autofs?

- Mount NFS shares **on demand** (when accessed)
- Unmount after idle timeout (saves resources)
- No need for fstab entries for every share
- Handles server unavailability gracefully

### Installing Autofs

```bash
sudo apt install -y autofs    # Debian/Ubuntu
sudo dnf install -y autofs    # RHEL/Fedora
```

### Architecture of Autofs

```
                 /etc/auto.master
                       |
        ┌──────────────┼──────────────┐
        |              |              |
   /etc/auto.misc /etc/auto.net /etc/auto.home
        |              |              |
    Mount points   Dynamic NFS    Home dir
    defined in    browsing       mounts
    auto.misc
```

### The Master Map (/etc/auto.master)

```bash
# /etc/auto.master
# Format:  mount-point  map-file  [options]

/misc   /etc/auto.misc    --timeout=60
/net    /etc/auto.net     --timeout=300
/home   /etc/auto.home    --timeout=600

# Direct map (uses /- as mount point)
/-      /etc/auto.direct
```

### Indirect Map Example

```bash
# /etc/auto.home
# Format:  key  options  location
# When someone accesses /home/username, it mounts server:/export/home/username

*       -rw,hard,intr,noatime     server:/export/home/&

# The & substitutes the key (wildcard)

# Specific entries
data    -rw,hard,intr             192.168.1.100:/export/data
docs    -ro,hard,intr             192.168.1.100:/export/docs

# With multiple replicas (failover)
projects   -rw,hard,intr   server1:/export/projects server2:/export/projects
```

### Direct Map Example

```bash
# /etc/auto.direct
# Format:  /full/path  options  location

/projects/alpha    -rw,hard,intr    server1:/export/projects/alpha
/projects/beta     -rw,hard,intr    server1:/export/projects/beta
/opt/shared        -rw,hard,intr    192.168.1.100:/export/opt
```

### Executable Map (/etc/auto.net)

```bash
# /etc/auto.net — built-in script that scans the network
# Usage: In /etc/auto.master:
/net    /etc/auto.net    --timeout=60

# Then access:
ls /net/server1/
ls /net/192.168.1.100/export/data

# Custom executable map
# /etc/auto.custom.sh (must be executable)
#!/bin/bash
echo "data -rw,hard,intr 192.168.1.100:/export/data"
echo "docs -ro,hard,intr 192.168.1.100:/export/docs"

# Reference in auto.master:
/mycustom   /etc/auto.custom.sh   --timeout=60
```

### Wildcard and Key Substitution

```bash
# /etc/auto.share
# The & is replaced with the key being accessed
*       -rw,hard,intr    192.168.1.100:/export/&

# So "ls /share/backups" tries to mount 192.168.1.100:/export/backups
# And "ls /share/data" tries 192.168.1.100:/export/data
```

### Starting and Managing Autofs

```bash
# Start autofs
sudo systemctl enable --now autofs

# Restart after config changes
sudo systemctl restart autofs

# Check automount status
sudo automount --status

# Force unmount idle mounts
sudo umount -a -t autofs
```

### Autofs Options

| Option | Description |
|--------|-------------|
| `--timeout=N` | Unmount after N seconds of inactivity |
| `--ghost` | Show mount point directories even when not mounted |
| `--browse` | Allow browsing of directory (NFSv4) |
| `--negative-timeout=N` | Cache "no entry" for N seconds |

### Debugging Autofs

```bash
# Run in foreground with debug
sudo automount -f -v

# Check logs
journalctl -u autofs -f

# Show current mounts (autofs entries will appear)
mount | grep autofs
```





[← Previous](09-section-5-nfsv41-and-pnfs.md) | [↑ Index](index.md) | [Next →](11-section-7-security.md)
