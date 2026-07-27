## 🔍 Section 1: How SSH Works

SSH (Secure Shell) is a protocol for securely connecting to remote systems.

### The Three Layers of SSH

```
┌──────────────────────────────────────┐
│    SSH Transport Layer (TCP 22)       │  ← Establishes encrypted connection
│    - Server authentication            │
│    - Key exchange                     │
│    - Encryption negotiation           │
├──────────────────────────────────────┤
│    SSH Authentication Layer           │  ← Verifies who you are
│    - Password                        │
│    - Public key                      │
│    - Keyboard-interactive            │
│    - GSSAPI (Kerberos)               │
├──────────────────────────────────────┤
│    SSH Connection Layer               │  ← Multiplexes multiple channels
│    - Interactive shell               │
│    - Remote command execution        │
│    - Port forwarding                 │
│    - X11 forwarding                  │
└──────────────────────────────────────┘
```

### The SSH Handshake

```
1. Client connects to server on port 22
2. Server sends its host key (public)
3. Client checks: is this host key in ~/.ssh/known_hosts?
4. Client and server perform key exchange (Diffie-Hellman)
5. Shared session key is established (SYMMETRIC encryption)
6. All further communication is encrypted with session key
7. Client authenticates (password or public key)
8. Session begins
```

### Host Keys

```bash
# Server identifies itself with a host key
ls /etc/ssh/ssh_host_*
# ssh_host_rsa_key         - RSA
# ssh_host_ecdsa_key      - ECDSA
# ssh_host_ed25519_key    - Ed25519 (most secure)

# Fingerprint of the host key (what you see on first connect)
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
```

When you connect for the first time:

```
$ ssh server.example.com
The authenticity of host 'server.example.com (192.168.1.100)' can't be established.
ED25519 key fingerprint is SHA256:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

This fingerprint is stored in `~/.ssh/known_hosts`. On subsequent connections, the server must present the same key — or SSH warns you of a possible man-in-the-middle attack.

---



---

[← Previous](02-level-1-basic-understanding-ssh.md) | [↑ Index](index.md) | [Next →](04-section-2-ssh-client-basics.md)
