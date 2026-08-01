## 🔍 Section 10: ssh-agent Forwarding and Connection Multiplexing

### ssh-agent Deep Dive

```bash
# Start agent (two methods)
eval "$(ssh-agent -s)"        # Start and set env vars
# or use your desktop's built-in agent (GNOME/KDE/macOS)

# Add key with timeout
ssh-add ~/.ssh/id_ed25519
ssh-add -t 3600 ~/.ssh/id_ed25519    # Expires after 1 hour

# List loaded keys
ssh-add -l                     # Fingerprints
ssh-add -L                     # Full public keys

# Remove keys
ssh-add -d ~/.ssh/id_ed25519   # Remove specific key
ssh-add -D                     # Remove all keys

# Kill agent
ssh-agent -k
```

### Agent Forwarding

Forward your local ssh-agent so you can jump through servers without storing keys:

```bash
# Enable forwarding for a session
ssh -A user@gateway.example.com

# From gateway, you can now SSH to internal hosts using YOUR local keys
gateway$ ssh internal-db       # Uses YOUR key, not a key on gateway

# In ~/.ssh/config (for specific hosts only!):
Host *.internal.example.com
    ForwardAgent yes
```

> **SECURITY WARNING:** Never use `ForwardAgent yes` as a wildcard. Anyone with root on the intermediate server can use your agent to authenticate as you.

### Connection Multiplexing

Reuse a single TCP connection for multiple SSH sessions — dramatically faster:

```bash
# ~/.ssh/config
Host *
    ControlMaster auto
    ControlPath ~/.ssh/sockets/%r@%h:%p
    ControlPersist 4h
```

```bash
# Manual multiplexing
ssh -M -S /tmp/mysocket user@server    # Master session
ssh -S /tmp/mysocket user@server       # Slave (reuses connection)
# The slave uses the master's TCP connection — no new handshake

# Check multiplex status
ssh -O check user@server

# Stop the master connection
ssh -O stop user@server
```

### ssh-agent Locking

```bash
# Lock agent with password
ssh-add -x                      # Lock (enter lock password)
ssh-add -X                      # Unlock

# Useful when stepping away from desk
```

### Practical Workflow

```bash
# Single sign-on for the day
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Now all SSH/scp/sftp/rsync commands use the agent
ssh server1
scp server2:file .
rsync -av server3:/data/ /data/

# All without typing your passphrase again
```



[← Previous](18-self-test-can-you-answer-these.md) | [↑ Index](index.md) | [Next →](20-section-11-proxyjump-and-bastion-hosts.md)
