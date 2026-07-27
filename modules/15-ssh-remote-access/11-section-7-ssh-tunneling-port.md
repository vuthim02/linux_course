## 🔍 Section 7: SSH Tunneling (Port Forwarding)

SSH can forward ports through encrypted channels.

### Local Port Forwarding

Access a remote service as if it were local:

```bash
# Access a database on a remote server through SSH
# Remote server has MySQL on port 3306, not exposed to internet
ssh -L 3306:localhost:3306 user@server.example.com

# Now on YOUR machine:
mysql -h localhost -P 3306
# This connects through the SSH tunnel to the remote MySQL
```

```
Your Machine                     SSH Server              MySQL Server
:3306  ←←←  SSH Tunnel  →→→  localhost:3306 →→→  localhost:3306
```

### Remote Port Forwarding

Expose a local service on a remote server:

```bash
# You have a web server on port 8080 on your machine
# You want someone on the remote server to access it
ssh -R 8080:localhost:8080 user@server.example.com

# Now on the REMOTE server:
curl http://localhost:8080
# This reaches your local web server through the tunnel
```

### Dynamic Port Forwarding (SOCKS Proxy)

Create a SOCKS proxy through SSH:

```bash
# All traffic through the remote server
ssh -D 1080 user@server.example.com

# Configure your browser to use SOCKS proxy:
# Proxy: SOCKS5, localhost, port 1080
# Now your web traffic appears to come from the SSH server
```

### Practical Tunnel Examples

```bash
# Access a web admin interface on a remote server
ssh -L 8080:localhost:80 user@server.example.com
# Then open: http://localhost:8080

# Access a remote PostgreSQL database through a jump host
ssh -L 5432:db.internal.example.com:5432 user@jumphost.example.com

# Multi-hop tunnel (through jump host to internal server)
ssh -L 8080:internal-web:80 user@jumphost.example.com

# Persistent tunnel (autossh — stays up)
autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" \
  -L 3306:localhost:3306 user@server.example.com
```

---



---

[← Previous](10-level-3-advanced-tunneling-hardening.md) | [↑ Index](index.md) | [Next →](12-section-8-hardening-ssh-security.md)
