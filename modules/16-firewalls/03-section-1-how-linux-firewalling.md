## 🔍 Section 1: How Linux Firewalling Works

### Netfilter — The Kernel Framework

All Linux firewalls (iptables, firewalld, nftables) are frontends to the same kernel subsystem: **netfilter**.

```
┌─────────────────────────────────────────────────────┐
│                    USER SPACE                        │
│                                                      │
│  iptables         firewalld         nft              │
│   (legacy)         (frontend)        (modern)        │
│       │               │                │            │
└───────┼───────────────┼────────────────┼────────────┘
        │               │                │
        ▼               ▼                ▼
┌─────────────────────────────────────────────────────┐
│                   KERNEL SPACE                       │
│                                                      │
│                   netfilter                          │
│                                                      │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐   │
│  │ PREROUT│  │ INPUT  │  │FORWARD │  │OUTPUT  │   │
│  │  ING   │  │        │  │        │  │        │   │
│  └────────┘  └────────┘  └────────┘  └────────┘   │
│  ┌────────┐                          ┌────────┐     │
│  │ POSTROU│                          │        │     │
│  │  TING  │                          │        │     │
│  └────────┘                          └────────┘     │
└─────────────────────────────────────────────────────┘
```

### The Five Netfilter Hooks

A packet traverses different hooks depending on its direction:

```
INCOMING PACKET (destined for this machine):

Packet arrives → PREROUTING → INPUT → Local Process
                    │
                    ▼ Check routing: is it for me?
                    │
                    ▼ No? → FORWARD (if forwarding enabled)

OUTGOING PACKET (from this machine):

Local Process → OUTPUT → POSTROUTING → Network
```

### The Three iptables Tables

| Table | Built-in Chains | Purpose |
|-------|----------------|---------|
| **filter** | INPUT, FORWARD, OUTPUT | Packet filtering (ALLOW/DENY) |
| **nat** | PREROUTING, OUTPUT, POSTROUTING | NAT (address translation) |
| **mangle** | PREROUTING, INPUT, FORWARD, OUTPUT, POSTROUTING | Packet modification (TOS, TTL) |
| **raw** | PREROUTING, OUTPUT | Connection tracking exceptions |
| **security** | INPUT, FORWARD, OUTPUT | SELinux security contexts |

### Packet Flow Through Tables and Chains

```
PREROUTING (raw → mangle → nat)
    │
    ▼
Routing Decision
    │
    ├── FOR LOCAL HOST: INPUT (mangle → filter) → Local Process
    │                                                    │
    └── FORWARDED: FORWARD (mangle → filter)             │
                                                         ▼
                                                  OUTPUT (raw → mangle → nat → filter)
                                                         │
                                                         ▼
                                                  POSTROUTING (mangle → nat)
```

---



---

[← Previous](02-level-1-basic-understanding-linux.md) | [↑ Index](index.md) | [Next →](04-section-2-iptables-basics.md)
