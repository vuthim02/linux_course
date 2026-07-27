## 🎫 Section 13: Kerberos

### 13.1 What is Kerberos?

Kerberos is a **network authentication protocol** that uses **tickets** instead of passwords. It provides **single sign-on (SSO)** — you authenticate once and get tickets for all services.

Named after Cerberus, the three-headed dog guarding Hades (the three heads are AS, TGS, and the service).

### 13.2 How Kerberos Works — The Ticket Granting Process

```
┌─────────┐          ┌───────────┐          ┌────────────┐
│  User   │          │    AS     │          │    TGS     │
│ (Alice) │          │   Auth    │          │  Ticket    │
│         │          │  Server   │          │  Granting  │
└────┬────┘          └─────┬─────┘          └─────┬──────┘
     │                     │                       │
     │  1. Request TGT     │                       │
     │────────────────────>│                       │
     │                     │                       │
     │  2. TGT (encrypted  │                       │
     │   with KDC secret)  │                       │
     │<────────────────────│                       │
     │                     │                       │
     │  3. Request service │                       │
     │   ticket for SSH    │                       │
     │  (send TGT)         │                       │
     │────────────────────────────────────────────>│
     │                     │                       │
     │  4. Service ticket  │                       │
     │  (encrypted with    │                       │
     │   service secret)   │                       │
     │<────────────────────────────────────────────│
     │                     │                       │
     │  5. Present ticket  │                       │
     │   to SSH server     │                       │
     │  (authenticate)     │                       │
     │                                             │
```

**Step-by-step:**

| Step | From | To | What Happens |
|------|------|----|-------------|
| 1 | User | AS | User sends `kinit alice` → AS looks up in LDAP |
| 2 | AS | User | AS sends back **Ticket Granting Ticket (TGT)** encrypted with KDC master key |
| 3 | User | TGS | User wants to access SSH. Sends TGT + request for SSH service ticket |
| 4 | TGS | User | TGS sends service ticket for `host/server.example.com` |
| 5 | User | SSH | User presents service ticket. SSH decrypts with its keytab — access granted |

**Key Concepts:**

- **KDC** = Key Distribution Center (the combined AS + TGS)
- **Realm** = Kerberos domain (e.g. `EXAMPLE.COM`, uppercase by convention)
- **Principal** = A unique identity (`alice@EXAMPLE.COM`, `host/server.example.com@EXAMPLE.COM`)
- **Keytab** = A file containing service principals' long-term keys
- **TGT** = Ticket Granting Ticket (your "passport" — proves you authenticated)
- **Service Ticket** = Ticket for a specific service (SSH, HTTP, NFS)

### 13.3 Kerberos Configuration

```ini
# /etc/krb5.conf
[libdefaults]
  default_realm = EXAMPLE.COM
  dns_lookup_realm = true
  dns_lookup_kdc = true
  ticket_lifetime = 24h
  renew_lifetime = 7d
  forwardable = true
  rdns = false

[realms]
  EXAMPLE.COM = {
    kdc = kdc.example.com:88
    admin_server = kdc.example.com:749
    default_domain = example.com
  }

[domain_realm]
  .example.com = EXAMPLE.COM
  example.com = EXAMPLE.COM
```

### 13.4 kinit, klist, kdestroy

```bash
# Authenticate and get a TGT
kinit alice@EXAMPLE.COM
# (enter password)

# List active tickets
klist
# Ticket cache: FILE:/tmp/krb5cc_10001
# Default principal: alice@EXAMPLE.COM
#
# Valid starting     Expires            Service principal
# 06/24/26 10:00:00  06/25/26 10:00:00  krbtgt/EXAMPLE.COM@EXAMPLE.COM
#         renew until 07/01/26 10:00:00

# Detailed view
klist -e
# Shows encryption types

# List all tickets including service tickets
klist -A

# Check if authentication is valid
kvno alice@EXAMPLE.COM

# Destroy tickets (logout)
kdestroy

# Destroy all tickets
kdestroy -A
```

### 13.5 kadmin (Kerberos Admin)

```bash
# Access admin interface
kadmin -p admin/admin@EXAMPLE.COM

# Inside kadmin:
kadmin: addprinc alice@EXAMPLE.COM
kadmin: addprinc -randkey host/server.example.com@EXAMPLE.COM
kadmin: ktadd -k /etc/krb5.keytab host/server.example.com@EXAMPLE.COM
kadmin: listprincs
kadmin: delprinc bob@EXAMPLE.COM
kadmin: modprinc -expire "2026-12-31" alice@EXAMPLE.COM
kadmin: modprinc -maxlife "12h" alice@EXAMPLE.COM
kadmin: quit
```

```bash
# Non-interactive
kadmin.local -q "addprinc alice"
kadmin -p admin/admin -q "listprincs"
```

### 13.6 Keytab Management

```bash
# Create keytab for a service
sudo ktadd -k /etc/krb5.keytab HTTP/server.example.com

# List keys in keytab
sudo klist -k /etc/krb5.keytab

# Test keytab authentication
kinit -k -t /etc/krb5.keytab HTTP/server.example.com
```

### 13.7 SSH with Kerberos

```bash
# /etc/ssh/sshd_config
GSSAPIAuthentication yes
GSSAPICleanupCredentials yes

# /etc/ssh/ssh_config
GSSAPIAuthentication yes
GSSAPIDelegateCredentials yes

# Then:
kinit alice@EXAMPLE.COM
ssh server.example.com  # No password!
```

### 13.8 NFS with Kerberos

```bash
# /etc/exports (on NFS server)
/export *(sec=krb5p,rw)

# Mount on client
mount -t nfs4 -o sec=krb5p server:/export /mnt
```

### 13.9 Kerberos Policies

```bash
# List policies
kadmin -q "list_policies"

# Create policy
kadmin -q "addpol users -minlength 8 -minclasses 3 -history 10"

# Apply policy to principal
kadmin -q "modprinc -policy users alice@EXAMPLE.COM"
```

---



---

[← Previous](15-section-12-freeipa.md) | [↑ Index](index.md) | [Next →](17-what-you-will-achieve.md)
