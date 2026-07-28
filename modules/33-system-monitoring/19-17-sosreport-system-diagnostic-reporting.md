## 17. `sosreport` — System Diagnostic Reporting

`sosreport` collects system configuration and diagnostic information into a compressed archive. It is the standard tool for generating support bundles for Red Hat, Ubuntu, and other distributions.

```
$ sudo dnf install sos           # RHEL/Fedora
$ sudo apt install sosreport     # Debian/Ubuntu
$ sudo sos report
```

Collects system configuration and diagnostic info into a compressed archive for support tickets.

**What it collects**:
- System information: hostname, kernel version, CPU, memory, disk layout
- Loaded kernel modules and their parameters
- Running services and their status
- Network configuration and interfaces
- Loaded kernel logs from `journalctl` or `/var/log/messages`
- Package lists and RPM/DPKG database

**Common options**:
- `sos report --list-plugins`: Show available collection plugins
- `sos report -o plugin1,plugin2`: Enable specific plugins only
- `sos report --batch`: Non-interactive mode for automated collection
- `sos report --tmp-dir /tmp/sos`: Output to a specific directory
- The resulting tarball (`/tmp/sosreport-*.tar.xz`) can be uploaded to Red Hat support or shared with colleagues

**When to use sosreport**: When opening a support ticket with a vendor. When performing root cause analysis after an incident. When documenting a system's state before making major changes. The archive provides a complete snapshot of the system at a point in time.


[← Previous](18-16-cockpit-web-based-server-administration.md) | [↑ Index](index.md) | [Next →](20-level-3-advanced-smart-prometheus.md)
