## ⭐ Level 2: Intermediary — SSH and Service Management

![SSH protocol — secure remote access architecture](https://upload.wikimedia.org/wikipedia/commons/7/75/Secure_Shell_-_SSH_protocol.svg)

*Secure Shell (SSH) protocol architecture (Wikimedia Commons / public domain)*

> **Level 2 Goal:** Configure and harden an SSH server, manage network services with systemd, implement security best practices, and monitor service health.

### What You'll Cover
- SSH server setup: `sshd_config` essentials for production
- Managing services with systemd: `systemctl start/stop/enable`
- Service unit files: understanding ExecStart, Restart, and WantedBy
- Monitoring service health: `systemctl status`, `journalctl -u`
- Firewalld integration: opening service ports safely

### Why This Level Matters

SSH is your front door to every Linux server. If it is misconfigured, you either lock yourself out or let attackers in. Hardening SSH is one of the first things you do on any new server. This level teaches you the specific `sshd_config` directives that matter and why.

Systemd service management is the other half of the equation. Every network service runs as a systemd unit. Understanding unit files — what `ExecStart` does, how `Restart` policies work, what `WantedBy` means — lets you configure, debug, and customize any service on your system.

### What You'll Practice

- Editing `/etc/ssh/sshd_config` to disable root login and password authentication
- Setting up SSH key-based authentication for secure remote access
- Writing a custom systemd unit file for a network service
- Using `systemctl status` and `journalctl -u` to monitor service health
- Configuring firewalld to allow SSH and HTTP while blocking everything else

> ⠿ **Warning:** Always test SSH configuration changes in a second terminal session before closing your current one. A broken `sshd_config` will lock you out of the server.





[← Previous](04-section-2-http-server.md) | [↑ Index](index.md) | [Next →](06-section-3-ssh-server.md)
