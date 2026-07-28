## ⭐ Level 2: Intermediary — File Serving, Domain Membership, and Client Tools

![Samba Standalone Server](https://upload.wikimedia.org/wikipedia/commons/thumb/5/55/Client-server_model.svg/220px-Client-server_model.svg.png)  
*Samba follows a client-server model for file sharing. Image credit: Wikimedia Commons.*

> **Level 2 Goal:** Configure Samba as a standalone file server and domain member. Mount CIFS shares on Linux, use smbclient for transfers, monitor connections with smbstatus, and integrate Windows users via Winbind.

### What You'll Cover
- Standalone Samba server configuration: shares, permissions, `valid users`
- Joining an Active Directory domain with `net ads join`
- Mounting CIFS shares on Linux: `mount -t cifs` and `/etc/fstab`
- Interactive file transfers with `smbclient` and `smbget`
- Monitoring active connections with `smbstatus`
- Winbind integration: mapping Windows SIDs to Linux UIDs

At this level you configure Samba for real-world file sharing and integrate it with existing Windows infrastructure.

At this level you will practice:

- **Share configuration**: In `smb.conf`, create `[documents]` with `path = /srv/samba/documents`, `valid users = @sambausers`, `writable = yes`. Create the directory, set permissions, and restart `smbd`. Use `chmod 2770` for group-level sharing.
- **Domain joining**: `net ads join -U admin_user` joins the Samba server to an Active Directory domain. This requires proper DNS resolution and time synchronization (NTP). After joining, you can authenticate AD users with `wbinfo -u` and `id DOMAIN\user`.
- **CIFS mounting**: `mount -t cifs //server/share /mnt -o username=user,domain=DOMAIN` mounts a Windows share. For fstab persistence, use a credentials file: `credentials=/root/.smbcreds` with `username=user` and `domain=DOMAIN` inside.
- **smbclient**: `smbclient //server/share -U user` gives an interactive FTP-like shell. Use `smbget -r smb://server/share/file` for recursive downloads. Both are essential for scripting and debugging.
- **smbstatus**: Shows active connections, open files, and locked resources. Use `smbstatus -L` for locks only. This is the first tool to check when users report "file in use" errors.


[← Previous](04-section-2-samba-overview.md) | [↑ Index](index.md) | [Next →](06-section-3-samba-as-standalone.md)
