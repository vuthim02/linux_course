## 🔍 Section 2: HashiCorp Vault Architecture

### Core Architecture

```
┌─────────────────────────────────────────────┐
│               Vault Server                   │
│  ┌───────────────────────────────────────┐  │
│  │          HTTP API (TCP 8200)          │  │
│  │  auth │ sec.eng │ sys │ audit │ cache │  │
│  └──────────────────┬────────────────────┘  │
│  ┌──────────────────▼────────────────────┐  │
│  │            Token Store                │  │
│  │   (token → policy → metadata)        │  │
│  └──────────────────┬────────────────────┘  │
│  ┌──────────────────▼────────────────────┐  │
│  │   Barrier (AES-256-GCM master key)    │  │
│  │   All data encrypted before storage   │  │
│  └──────────────────┬────────────────────┘  │
│  ┌──────────────────▼────────────────────┐  │
│  │   Storage Backend (Raft/Consul/File)  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### Sealed vs Unsealed

On startup Vault is **sealed** — the storage backend data is encrypted with a master key and cannot be read. The **unseal process** reconstructs the master key from Shamir shares (splits into N shares, threshold T required) or via auto-unseal (master key encrypted by cloud KMS).

**Shamir's Secret Sharing (5/3):** Master key split into 5 shares. Any 3 can reconstruct. Prevents any single person from unsealing Vault.

**Auto-Unseal flow:** Vault starts → reads encrypted master key from storage → sends to cloud KMS (AWS KMS/GCP KMS/Azure KV) for decryption → Vault decrypts master key in memory → unsealed. No human intervention needed.

### Storage Backends

| Backend | HA | Notes |
|---------|----|-------|
| Integrated Raft | Yes | No external dependency, production choice |
| Consul | Yes | External KV store, proven |
| File | No | Dev/test only |
| S3/GCS/Azure | No | + external HA coordination |

### Vault Agent

Vault Agent runs alongside apps to handle authentication, caching, and template rendering. Applications read secrets from local files/Unix socket instead of contacting Vault directly.

```
Pod ┌─────────────────────────────┐
    │ App Container               │
    │ reads /etc/secrets/*        │
    └─────────┬───────────────────┘
              │ localhost:8200
    ┌─────────▼───────────────────┐
    │ Vault Agent Sidecar         │
    │ auto-auth → cache → template│
    └─────────┬───────────────────┘
              │ mTLS
              ▼ Vault Server
```





[← Previous](02-section-1-why-secrets-management.md) | [↑ Index](index.md) | [Next →](04-section-3-vault-auth-methods.md)
