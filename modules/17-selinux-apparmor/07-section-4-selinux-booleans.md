## 🔍 Section 4: SELinux Booleans

Booleans are on/off switches for common policies. They let you adjust SELinux without writing policy.

### Managing Booleans

```bash
# List all booleans
getsebool -a

# List booleans with description
semanage boolean -l | head -30

# Common web server booleans:
# httpd_enable_homedirs       — Allow httpd to read home directories
# httpd_can_network_connect   — Allow httpd to make network connections
# httpd_can_sendmail          — Allow httpd to send mail
# httpd_use_nfs              — Allow httpd to access NFS files

# Get a specific boolean
getsebool httpd_can_network_connect

# Set a boolean (temporary, lost on reboot)
sudo setsebool httpd_can_network_connect on

# Set a boolean (permanent)
sudo setsebool -P httpd_can_network_connect on
```

### Common Booleans for Sysadmins

```bash
# Allow web servers to make outbound connections
sudo setsebool -P httpd_can_network_connect on

# Allow SSH to access home directories (for sftp)
sudo setsebool -P ssh_chroot_rw_homedirs on

# Allow NFS to work with SELinux
sudo setsebool -P nfs_export_all_rw on

# Allow daemons to use DNS
sudo setsebool -P daemons_use_tty on
```





[← Previous](06-section-3-selinux-contexts.md) | [↑ Index](index.md) | [Next →](08-level-3-advanced-troubleshooting-denials.md)
