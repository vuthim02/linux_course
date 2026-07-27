## 📋 Summary — Complete Command Reference for Part 22

### Level 1: Basic Commands — DHCP and HTTP

| Command | Action |
|---------|--------|
| `sudo systemctl start isc-dhcp-server` | Start DHCP server |
| `sudo systemctl start apache2` | Start Apache (Debian) |
| `sudo systemctl start httpd` | Start Apache (RHEL) |
| `curl http://localhost` | Test web server locally |
| `cat /var/lib/dhcp/dhcpd.leases` | View DHCP leases |

### Level 2: Intermediary Commands — SSH and Service Management

| Command | Action |
|---------|--------|
| `ss -tlnp` | List listening TCP ports |
| `sudo sshd -t` | Test SSH config validity |
| `ssh-keygen -t ed25519` | Generate SSH key pair |
| `ssh-copy-id user@host` | Copy public key to server |
| `sudo journalctl -u sshd -f` | Follow SSH logs |
| `sudo ufw allow ssh` | Allow SSH in firewall |

### Level 3: Advanced Commands — Troubleshooting

| Command | Action |
|---------|--------|
| `ssh -vvv user@host` | Verbose SSH debug |
| `nc -zv host port` | Test port connectivity |
| `tcpdump -i eth0 port 67` | Capture DHCP traffic |
| `sudo strace -p PID` | Trace service system calls |

---



---

[← Previous](13-deep-understanding-network-services-internals.md) | [↑ Index](index.md) | [Next →](15-whats-coming-in-part-23.md)
