## ⭐ Level 1: Basic — SMB/CIFS Concepts and Samba Overview

![SMB Protocol Evolution](https://upload.wikimedia.org/wikipedia/commons/thumb/a/a1/Samba_logo.svg/220px-Samba_logo.svg.png)  
*The Samba logo — bridging Linux and Windows file sharing. Image credit: Wikimedia Commons.*

> **Level 1 Goal:** Understand the SMB/CIFS protocol family — its history, dialect negotiation (SMB1, SMB2, SMB3), and how the Samba suite (smbd, nmbd, winbindd) implements the protocol on Linux.

### What You'll Cover
- SMB protocol evolution: SMB1 (insecure, deprecated), SMB2, SMB3 with encryption
- CIFS as Microsoft's implementation of SMB
- The Samba suite: `smbd` (file sharing), `nmbd` (NetBIOS), `winbindd` (AD integration)
- Samba configuration: `smb.conf` structure and directives
- Installing Samba on RHEL/Ubuntu
- Checking Samba status: `systemctl status smbd`, testparm

SMB (Server Message Block) is the file sharing protocol used by Windows. Samba implements this protocol on Linux, enabling seamless file sharing between Linux servers and Windows clients.

At this level you will learn:

- **SMB versions**: SMB1 is deprecated due to security vulnerabilities (WannaCry exploited it). SMB2 (Windows Vista+) is faster and more secure. SMB3 (Windows 8+) adds end-to-end encryption, multichannel, and persistent handles. Always configure Samba to disable SMB1.
- **Samba daemons**: `smbd` handles file sharing and authentication (ports 139/445). `nmbd` handles NetBIOS name resolution (ports 137/138) — mostly legacy. `winbindd` maps Windows SIDs to Linux UIDs for domain integration.
- **`smb.conf`**: The main configuration file. Sections like `[global]`, `[sharename]` define server behavior and shares. Use `testparm` to validate syntax before restarting services.
- **Installation**: RHEL: `dnf install samba`. Ubuntu: `apt install samba`. After installation, `systemctl enable --now smbd` starts the service. Open firewall ports 139/tcp and 445/tcp.


[← Previous](01-what-you-will-achieve-in.md) | [↑ Index](index.md) | [Next →](03-section-1-what-is-smbcifs.md)
