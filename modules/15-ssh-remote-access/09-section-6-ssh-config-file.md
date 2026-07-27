## 🔍 Section 6: SSH Config File (~/.ssh/config)

Create shortcuts for frequently accessed servers.

### Basic Host Entries

```bash
cat ~/.ssh/config

# Defaults for all hosts
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 3

# Specific host
Host webserver
    HostName 192.168.1.100
    User admin
    Port 2222
    IdentityFile ~/.ssh/webserver-key
```

Once configured:

```bash
# Instead of:
ssh admin@192.168.1.100 -p 2222 -i ~/.ssh/webserver-key

# You just type:
ssh webserver
```

### Advanced Config Examples

```bash
# Multiple names for same host
Host web web1 webserver
    HostName 192.168.1.100
    User admin

# Wildcard for a domain
Host *.example.com
    User sysadmin
    IdentityFile ~/.ssh/example-key
    ForwardAgent yes

# Jump host (bounce through one server to reach another)
Host internal-server
    HostName 10.0.0.50
    User sysadmin
    ProxyJump jumphost.example.com
    # Or for older SSH: ProxyCommand ssh jumphost.example.com -W %h:%p

# Force command on connection
Host readonly
    HostName 192.168.1.100
    User backup
    IdentityFile ~/.ssh/readonly-key
    RemoteCommand /usr/local/bin/readonly-shell
    RequestTTY yes

# Local port forwarding shortcut
Host tunnel
    HostName db.example.com
    User admin
    LocalForward 3306 localhost:3306
```

### SSH Config Options

```bash
Host                    # Pattern to match (can use *)
HostName                # Actual hostname or IP
Port                    # Port number (default: 22)
User                    # Username
IdentityFile            # Path to private key
ProxyJump               # Jump host (bastion)
LocalForward            # Local port → remote port
RemoteForward           # Remote port → local port
ForwardAgent            # Forward SSH agent (yes/no)
ServerAliveInterval     # Keep-alive interval (seconds)
ServerAliveCountMax     # Failed keep-alive limit
StrictHostKeyChecking   # How to handle unknown hosts (ask/yes/no)
UserKnownHostsFile      # Custom known_hosts file
LogLevel                # Verbosity (QUIET, INFO, VERBOSE, DEBUG)
Compression             # Enable compression (yes/no)
```

---



---

[← Previous](08-section-5-file-transfer-scp.md) | [↑ Index](index.md) | [Next →](10-level-3-advanced-tunneling-hardening.md)
