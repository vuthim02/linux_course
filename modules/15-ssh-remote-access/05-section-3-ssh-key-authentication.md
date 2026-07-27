## 🔍 Section 3: SSH Key Authentication

Key-based authentication is more secure and more convenient than passwords.

### How It Works

```
Client has:    private key (secret)   +   public key (shared)
Server has:    public key in ~/.ssh/authorized_keys

1. Client requests public key authentication
2. Server checks if client's public key is in authorized_keys
3. Server sends a challenge (random number encrypted with public key)
4. Client decrypts with private key and sends back the number
5. Server verifies → authentication successful
```

### Generating SSH Keys

```bash
# Generate an Ed25519 key (most secure, recommended)
ssh-keygen -t ed25519 -C "my-email@example.com"

# Generate an RSA key (compatible with older systems)
ssh-keygen -t rsa -b 4096 -C "my-email@example.com"

# Output:
# Your identification has been saved in /home/user/.ssh/id_ed25519
# Your public key has been saved in /home/user/.ssh/id_ed25519.pub
```

### Key File Structure

```bash
ls ~/.ssh/
# id_ed25519          — Private key (NEVER share this)
# id_ed25519.pub      — Public key (safe to share)
# authorized_keys     — Public keys allowed to connect
# known_hosts         — Host keys of servers you've connected to
# config              — Client configuration (shortcuts)
```

### Copying Your Public Key to a Server

```bash
# Method 1: ssh-copy-id (easiest, requires password once)
ssh-copy-id user@server.example.com

# Method 2: Manually append
cat ~/.ssh/id_ed25519.pub | ssh user@server.example.com \
  "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Method 3: Using ssh-copy-id on non-standard port
ssh-copy-id -p 2222 user@server.example.com
```

### Key Permissions (Critical!)

```bash
# Correct permissions for SSH to work
chmod 700 ~/.ssh         # Directory: 700 (drwx------)
chmod 600 ~/.ssh/id_ed25519       # Private key: 600 (-rw-------)
chmod 644 ~/.ssh/id_ed25519.pub   # Public key: 644 (-rw-r--r--)
chmod 600 ~/.ssh/authorized_keys  # Authorized keys: 600
chmod 644 ~/.ssh/known_hosts      # Known hosts: 644
```

If permissions are wrong, SSH will refuse to use the keys.

### Testing Key Authentication

```bash
# Connect — should now work WITHOUT a password
ssh user@server.example.com

# If it still asks for a password:
ssh -v user@server.example.com | grep "Authenticated"
# Look for "Authenticated with partial success" or "Authentication succeeded"
```

### ssh-agent (Locking Private Keys in Memory)

```bash
# Start the agent in your session
eval "$(ssh-agent -s)"

# Add your private key (enter passphrase once per session)
ssh-add ~/.ssh/id_ed25519

# List loaded keys
ssh-add -l

# Remove all keys
ssh-add -D
```

---



---

[← Previous](04-section-2-ssh-client-basics.md) | [↑ Index](index.md) | [Next →](06-level-2-intermediary-configuring-ssh.md)
