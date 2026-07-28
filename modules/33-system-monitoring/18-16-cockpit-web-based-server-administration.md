## 16. Cockpit — Web-Based Server Administration

Cockpit provides a modern web interface for server administration. It shows real-time performance graphs, provides a terminal, and manages storage, networking, and containers.

```
$ sudo apt install cockpit
$ sudo systemctl enable --now cockpit.socket
# Access at https://your-server:9090
```

Features: real-time graphs, terminal access, storage management, container management.

**Key features**:
- **Performance graphs**: CPU, memory, disk, and network usage over time with interactive time range selection
- **Terminal**: Access a root shell directly from the browser — useful when SSH is down
- **Storage**: View and manage LVM volumes, RAID arrays, partitions, and NFS mounts
- **Networking**: Configure interfaces, bonds, bridges, and firewalls
- **Podman containers**: Manage containers, images, and pods (Cockpit 270+)
- **Logs**: Browse systemd journal with filters for priority, unit, and time range
- **User management**: Create and manage local user accounts

**When to use Cockpit**: For quick server overviews when you do not want to SSH in. For non-technical users who need to see server status. For environments where multiple admins share server access and need a unified view. Cockpit does not replace SSH — it complements it.


[← Previous](17-15-ncdu-ncurses-disk-usage.md) | [↑ Index](index.md) | [Next →](19-17-sosreport-system-diagnostic-reporting.md)
