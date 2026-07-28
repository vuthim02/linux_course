## 🧠 Section 15: Deep Understanding

### 15.1 How OpenLDAP Backend Works

**MDB** (Memory-Mapped Database) is the modern backend for OpenLDAP. Previous backends were **BDB** (Berkeley DB) and **HDB** (Hierarchical BDB). All three are key-value stores, but MDB is vastly superior.

| Feature | BDB | HDB | MDB |
|---------|-----|-----|-----|
| Hierarchy | Flat | Nested entries | Nested entries |
| Performance | Slow under write load | Better | **Excellent** |
| Corruption | Fragile | Less fragile | **Crash-safe** (read-only memory map) |
| Database size | Limited | Limited | **Terabytes** (mmap) |
| Concurrent readers | Configurable | Configurable | **Unlimited** (MVCC) |
| Configuration | `olcDbMode` | `olcDbMode` | `olcDbMaxSize` |
| Default in | OpenLDAP < 2.4 | Never | OpenLDAP ≥ 2.4.40 |

MDB uses **memory-mapped files** (mmap). The entire database is mapped into virtual memory. This means:

- Multiple processes can read the same data without locking
- Reads never block writes (Multi-Version Concurrency Control)
- On crash, the database is always consistent (no journal recovery)
- Only explicit `fsync` on writes

Backend file layout (`/var/lib/ldap/`):

```
data.mdb       — The main database (all entries, all attributes)
lock.mdb       — Lock file (tiny, for write serialization)
alock.mdb      — Alarm lock
cn=accesslog/  — Access log database (for delta-syncrepl)
```

### 15.2 How PAM Modules Stack

PAM uses a **stack** of modules. Each module returns success or failure. The control flags determine behavior:

| Flag | Meaning |
|------|---------|
| `required` | Must succeed. If fails, continue checking other modules but deny at end. |
| `requisite` | Must succeed. If fails, **immediately** deny (skip remaining modules). |
| `sufficient` | If succeeds, **immediately** accept (skip remaining). If fails, continue. |
| `optional` | Not critical. Result used only if no other module determined outcome. |
| `include` | Include another PAM config file. |
| `substack` | Like include but with its own stack. |

**Typical PAM auth stack for LDAP:**

```
auth  [success=2 default=ignore]  pam_unix.so nullok_secure
auth  [success=1 default=ignore]  pam_ldap.so use_first_pass
auth  requisite                   pam_deny.so
auth  required                    pam_permit.so
```

**Flow for `su - alice`:**

```
1. pam_unix.so          → checks /etc/shadow first (local users)
                           → if alice not in /etc/shadow, ignore
2. pam_ldap.so          → prompts for password, sends to LDAP
                           → if password correct, success=1 skips to pam_permit
                           → if password wrong, goes to next
3. pam_deny.so          → if we get here, authentication failed
4. pam_permit.so        → should not be reached if denied
```

**For SSSD:**

```
auth  sufficient        pam_sss.so forward_pass
auth  required          pam_unix.so nullok_secure use_first_pass
```

The `pam_sss.so` module checks SSSD's cache first for fast response.

### 15.3 How NSS Calls nss_ldap

NSS is configured in `/etc/nsswitch.conf`. Each database (passwd, group, shadow) has a list of sources:

```
passwd:  compat systemd ldap
```

When `getent passwd alice` runs:

1. **glibc** checks `nsswitch.conf` → sources are `compat`, `systemd`, `ldap`
2. **compat** (nss_compat.so) → checks `/etc/passwd` for local users
3. **systemd** (nss_systemd.so) → checks systemd user database (DynamicUser)
4. **ldap** (nss_ldap.so) → calls `nslcd` via Unix socket `/var/run/nslcd/socket`
5. **nslcd** → connects to LDAP server, performs search `(&(objectClass=posixAccount)(uid=alice))`
6. Returns result → glibc formats as `struct passwd` → application gets user entry

For **SSSD**, the source is `sss`:

```
passwd:  compat systemd sss
```

Here, `nss_sss.so` talks to SSSD via D-Bus, not via nslcd.

### 15.4 The LDAP Protocol

LDAP is an **application-layer protocol** running over TCP (port 389) or TLS (port 636). Operations use **ASN.1/BER** encoding.

**Core LDAP Operations:**

| Operation | Code | Purpose |
|-----------|------|---------|
| Bind | 0x60 | Authenticate (prove identity) |
| Search | 0x63 | Query the directory |
| Compare | 0x6E | Test if an attribute equals a value |
| Add | 0x68 | Add a new entry |
| Delete | 0x6A | Delete an entry |
| Modify | 0x66 | Change attribute values |
| ModDN | 0x6C | Rename or move an entry |
| Unbind | 0x42 | Close the connection gracefully |
| Abandon | 0x50 | Cancel a pending operation |
| Extended Operation | 0x77 | Custom operations (StartTLS, WhoAmI, Password Modify) |

**The Bind Operation (Simplified):**

```
Client:                              Server:
  |                                     |
  |---- Bind Request ------------------>|
  |    version = 3                      |
  |    name = "cn=admin,dc=example,dc=com"
  |    authentication = simple          |
  |    credentials = "secret"           |
  |                                     |
  |<--- Bind Response ------------------|
  |    result code = 0 (success)        |
  |                                     |
```

**The Search Operation (Simplified):**

```
Client:                              Server:
  |                                     |
  |---- Search Request ---------------->|
  |    baseObject = "dc=example,dc=com" |
  |    scope = wholeSubtree             |
  |    derefAliases = neverDerefAliases |
  |    sizeLimit = 0 (no limit)         |
  |    timeLimit = 0 (no limit)         |
  |    filter = "(uid=alice)"           |
  |    attributes = [ "cn", "mail" ]    |
  |                                     |
  |<--- Search Result Entry ------------|
  |    dn: uid=alice,ou=People,...      |
  |    cn: Alice Smith                  |
  |    mail: alice@example.com          |
  |                                     |
  |<--- Search Result Done -------------|
  |    result code = 0                  |
  |    matched entries = 1              |
  |                                     |
```

**LDAP Result Codes:**

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Operations Error |
| 2 | Protocol Error |
| 10 | Referral |
| 13 | Confidentiality Required |
| 14 | SASL Bind In Progress |
| 16 | No Such Attribute |
| 17 | Undefined Attribute Type |
| 20 | Attribute or Value Exists |
| 32 | No Such Object |
| 33 | Alias Problem |
| 34 | Invalid DN Syntax |
| 48 | Inappropriate Authentication |
| 49 | **Invalid Credentials** — wrong password! |
| 50 | Insufficient Access Rights |
| 51 | Busy |
| 52 | Unavailable |
| 53 | Unwilling to Perform |
| 80 | Other (server-specific error) |

### 15.5 ASN.1 / BER Encoding

LDAP is encoded using **BER** (Basic Encoding Rules) for **ASN.1** (Abstract Syntax Notation One).

An ASN.1 value is encoded as **TLV** (Type-Length-Value):

```
+--------+--------+--------+
|  TYPE  | LENGTH | VALUE  |
|  1-4B  | 1-126B | var.   |
+--------+--------+--------+
```

For example, the LDAP Bind Request:

```
Tag 0x60 (APPLICATION 0 — Bind Request)
Length = 30 bytes
  Tag 0x02 (INTEGER)
  Length = 1
  Value = 03 (LDAP version 3)

  Tag 0x04 (OCTET STRING)
  Length = 28
  Value = "cn=admin,dc=example,dc=com"

  Tag 0x80 (CONTEXT-SPECIFIC 0 — simple auth)
  Length = 6
  Value = "secret"
```

You can see BER encoding with a packet capture:

```bash
# Capture LDAP traffic
sudo tcpdump -i any -X port 389
# The hex contains the BER-encoded LDAP operations
```

### 15.6 LDAP Referrals and Chaining

When an LDAP server does not hold the requested data, it can return a **referral** (code 10):

```bash
ldapsearch -x -b dc=other,dc=com '(uid=alice)'
# Result: Referral (10)
# Matched DN: dc=other,dc=com
# Referral: ldap://other-server.example.com/dc=other,dc=com
```

Clients can follow referrals automatically:

```bash
ldapsearch -x -b dc=example,dc=com -E 'chaining=resolve' '(uid=alice)'
```





[← Previous](18-section-14-15-hands-on-practices.md) | [↑ Index](index.md) | [Next →](20-section-16-command-reference.md)
