## 🔍 Section 8: WireGuard

### What Is WireGuard?

WireGuard is a modern VPN protocol that aims to be faster, simpler, and more secure than IPsec or OpenVPN. It is implemented as a kernel module (~4,000 lines of code) and has been part of the Linux kernel since 5.6.

### Architecture

```
┌─────────────┐                    ┌─────────────┐
│   Peer A    │     Encrypted      │   Peer B    │
│ 10.0.0.1/24│ ◄────────────────► │ 10.0.0.2/24│
│ wg0         │   UDP :51820       │ wg0         │
└──────┬──────┘                    └──────┬──────┘
       │                                   │
       │   ┌─────────────────────────┐    │
       └──►│ WireGuard Kernel Module │◄───┘
           │                         │
           │ • ChaCha20Poly1305      │
           │ • Noise_IK handshake    │
           │ • Timers & roaming      │
           │ • Cookie defense        │
           └─────────────────────────┘
```

### WireGuard Kernel Internals

**Cryptographic Primitives:**
- **Symmetric encryption:** ChaCha20Poly1305 (authenticated encryption)
- **Key exchange:** Curve25519 ECDH (X25519)
- **Hashing:** BLAKE2s (for session key derivation)
- **Handshake:** Noise protocol framework (Noise_IK_25519_ChaChaPoly_BLAKE2s)

**Noise Protocol (IK pattern):**
```
→ e, es, s, ss
← e, ee, se
```

This means:
1. Initiator sends: ephemeral key, encrypted static key, signature
2. Responder replies with: ephemeral key, derived session keys
3. Both sides now share symmetric session keys for data

**WireGuard Handshake (Step-by-step):**

```
Peer A                              Peer B
  │                                   │
  │ 1. Generate ephemeral keypair     │
  │    (e_priv, e_pub)                │
  │                                   │
  │ 2. msg1 = Handshake initiation    │
  │    ┌──────────────────────────────►│
  │    │ sender_index                 │
  │    │ unencrypted_ephemeral        │
  │    │ encrypted_static             │
  │    │ encrypted_timestamp          │
  │    │ mac1, mac2                   │
  │    └──────────────────────────────►│
  │                                   │
  │                                   │ 3. Compute DH:
  │                                   │    e_pub * s_priv → shared key
  │                                   │    Decrypt static, verify timestamp
  │                                   │ 4. Generate ephemeral keypair
  │                                   │
  │                                   │ 5. msg2 = Handshake response
  │    ◄──────────────────────────────┐
  │    │ sender_index                 │
  │    │ unencrypted_ephemeral        │
  │    │ encrypted_nothing            │
  │    │ mac1                         │
  │    └──────────────────────────────┤
  │                                   │
  │ 6. Verify, derive session keys    │
  │    (S1, S2 for encryption)        │
  │                                   │
  │ 7. msg3 = Cookie reply            │
  │    ┌──────────────────────────────►│ 8. Session established
  │    │ (empty, just confirms)       │    Data transport begins
  │    └──────────────────────────────►│
```

**Data Transport:**
- Each peer maintains a session with a 64-bit counter
- Each packet is encrypted with ChaCha20Poly1305 using session-derived key
- Includes a message counter to prevent replay attacks

**Roaming:**
WireGuard associates a peer with its public key, not its IP address. If a peer's IP changes (e.g., a mobile client), WireGuard detects the new source IP from an incoming packet and updates its endpoint transparently. This is built into the protocol — no reconnection needed.

**Timers:**
- `persistent_keepalive` — sends empty packets every N seconds to keep NAT mappings alive
- `rekey_after_time` — renegotiates session keys every 120 seconds by default
- `handshake_timeout` — retry handshake every 3 seconds if no response

**Cookie Defense:**
To prevent DoS attacks (like Amplification attacks where a small handshake triggers a large response), WireGuard uses a cookie mechanism. A peer receiving a handshake from an unknown IP first sends a cookie, and the initiator must include the cookie in its handshake before receiving a full response.

### Installing WireGuard

```bash
# Most modern kernels include WireGuard. Check:
modinfo wireguard
# If not found:
sudo apt install wireguard-dkms wireguard-tools
# Install on Ubuntu/Debian
sudo apt install wireguard
# Install on RHEL/CentOS 8+
sudo dnf install wireguard-tools
```

### Configuration

**Server configuration** `/etc/wireguard/wg0.conf`:
```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = gN65s7y7vF6s5h4g3f2d1s0a9z8x7c6v5b4n3m2l1k=

# Peer 1: laptop
[Peer]
PublicKey = 7J34kL2m9nB5vC6xZ1qW8eR4tY7uI3oP5aS6dF7gH8jK9l=
AllowedIPs = 10.0.0.2/32

# Peer 2: server
[Peer]
PublicKey = fR5tG6hY7jU8kI9lO0pP1aQ2sW3dE4rF5tG6hY7jU8k=
AllowedIPs = 10.0.0.3/32
```

**Client configuration** `/etc/wireguard/wg0.conf`:
```ini
[Interface]
Address = 10.0.0.2/24
PrivateKey = 4jH8kL9m0nB1vC2xZ3aQ4wS5eD6rF7gT8yU9iI0oP1a=
DNS = 1.1.1.1, 8.8.8.8

[Peer]
PublicKey = 5gH6jK7lZ8x9cV0bN1mQ2wE3rT4yU5iO6pP7aS8dF9gH=
Endpoint = vpn.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
```

### Key Generation

```bash
# Generate private key
wg genkey | tee private.key | wg pubkey > public.key

# Generate pre-shared key (optional, adds symmetric layer)
wg genpsk > psk.key

# View keys
cat private.key
cat public.key

# Generate a full configuration with keys
umask 077
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key
wg genkey | tee /etc/wireguard/client_private.key | wg pubkey > /etc/wireguard/client_public.key
```

### Bringing Up the Interface

```bash
# Bring up WireGuard
sudo wg-quick up wg0

# Check status
sudo wg show

# Expected output:
# interface: wg0
#   public key: 5gH6jK7lZ8x9cV0bN1mQ2wE3rT4yU5iO6pP7aS8dF9gH=
#   private key: (hidden)
#   listening port: 51820
#
# peer: 7J34kL2m9nB5vC6xZ1qW8eR4tY7uI3oP5aS6dF7gH8jK9l=
#   endpoint: 203.0.113.5:51820
#   allowed ips: 10.0.0.2/32
#   latest handshake: 1 minute ago
#   transfer: 1.2 MiB received, 3.4 MiB sent

# Verbose status
sudo wg showconf wg0

# Test connectivity
ping 10.0.0.2

# Bring down
sudo wg-quick down wg0

# Enable at boot
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

### MTU Considerations

WireGuard adds 60 bytes of overhead (20 IP + 8 UDP + 4 type + 4 key_index + 8 counter + 16 Poly1305 tag = 60):

```ini
[Interface]
Address = 10.0.0.1/24
PrivateKey = ...
MTU = 1420  # 1500 - 60 - 20 (for PPPoE: 1492 - 60 - 8 = 1424)
```

---



---

[← Previous](08-section-7-hubble.md) | [↑ Index](index.md) | [Next →](10-section-9-wireguard-in-practice.md)
