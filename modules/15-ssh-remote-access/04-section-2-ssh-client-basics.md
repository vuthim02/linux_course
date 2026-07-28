## 🔍 Section 2: SSH Client Basics

### Connecting to a Server

```bash
# Basic connection
ssh user@server.example.com

# Connect on a non-default port
ssh -p 2222 user@server.example.com

# Connect and run a command (then exit)
ssh user@server.example.com "ls -la /tmp"

# Connect with verbose output (debugging)
ssh -v user@server.example.com

# Even more verbose
ssh -vvv user@server.example.com
```

### Running Remote Commands

```bash
# Single command
ssh user@server "uptime"

# Multiple commands
ssh user@server "df -h && free -h"

# Pipeline (local data through SSH to remote)
cat localfile.txt | ssh user@server "cat > /tmp/remotefile.txt"

# Remote output to local file
ssh user@server "cat /var/log/syslog" > local-syslog.txt
```

### The SSH Escape Sequence

```bash
# When connected, type ~? to see escape sequences
# ~.  — terminate connection (if stuck)
# ~^Z — suspend SSH
# ~C  — open command line (for port forwarding)
```





[← Previous](03-section-1-how-ssh-works.md) | [↑ Index](index.md) | [Next →](05-section-3-ssh-key-authentication.md)
