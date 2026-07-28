## 🔍 Section 7: Security

### Export Restrictions

```bash
# /etc/exports — restrict by IP, subnet, or domain

# Single host
/export/data  192.168.1.100(rw,sync)

# Subnet (CIDR)
/export/data  10.0.0.0/8(rw,sync)

# Domain wildcard
/export/data  *.example.com(rw,sync)

# Multiple clients
/export/data  192.168.1.0/24(rw) 10.0.0.5(rw)

# All (dangerous — avoid)
/export/data  *(rw,no_root_squash)
```

### root_squash — The Most Important Security Option

```bash
# root_squash (DEFAULT):
#   Client root (uid=0) is mapped to nobody/nfsnobody (uid=65534)
#   Prevents client root from writing to the export as root
#   Without root_squash, client root can:
#     - chown any file
#     - setuid anything
#     - delete protected files

# no_root_squash (DANGEROUS):
#   Client root keeps root privileges
#   Only use for dedicated NFS servers where you trust clients

# all_squash:
#   EVERY user is squashed to anonymous
#   Use for public read-only exports

# Example: secure configuration
/export/public   *(ro,all_squash,no_subtree_check)
/export/internal 192.168.1.0/24(rw,root_squash,no_subtree_check)
```

### Squash Behavior Matrix

| Export Option | Client root (uid=0) | Client user (uid=1000) |
|--------------|---------------------|----------------------|
| `no_root_squash` | Server root (uid=0) | Server user (uid=1000) |
| `root_squash` (default) | nobody (uid=65534) | Server user (uid=1000) |
| `all_squash` | nobody (uid=65534) | nobody (uid=65534) |

### sec= Options In Detail

```bash
# /etc/exports with different security flavors
/export/public    *(ro,sec=sys)
/export/internal  *(rw,sec=sys:krb5p)    # sys OR krb5p accepted
/export/secure    *(rw,sec=krb5i:krb5p)  # krb5i OR krb5p (no sys fallback)
/export/topsecret *(rw,sec=krb5p)        # krb5p only (encrypted)

# Mount with specific sec=
sudo mount -t nfs4 -o sec=krb5p server:/export/topsecret /mnt/secret
```

### NFS over TLS

Since Linux kernel 6.x, NFS can run over TLS for encryption without Kerberos complexity:

```bash
# Server side:
# Configure nfsd to use TLS
echo "1" | sudo tee /sys/module/sunrpc/parameters/enable_tls

# Generate certificates (or use Let's Encrypt)
sudo openssl req -x509 -newkey rsa:4096 -keyout /etc/nfs/nfsd-key.pem \
  -out /etc/nfs/nfsd-cert.pem -days 365 -nodes

# Client side:
sudo mount -t nfs4 -o xprtsec=tls server:/export/data /mnt/data
```

### Firewall Rules for NFS

```bash
# NFSv4 only (single port 2049)
iptables -A INPUT -p tcp --dport 2049 -s 192.168.1.0/24 -j ACCEPT

# NFSv3 needs more ports
iptables -A INPUT -p tcp --dport 111    -s 192.168.1.0/24 -j ACCEPT  # rpcbind
iptables -A INPUT -p tcp --dport 2049   -s 192.168.1.0/24 -j ACCEPT  # nfsd
iptables -A INPUT -p tcp --dport 40001  -s 192.168.1.0/24 -j ACCEPT  # mountd (fixed)
iptables -A INPUT -p tcp --dport 40002  -s 192.168.1.0/24 -j ACCEPT  # statd
iptables -A INPUT -p tcp --dport 40004  -s 192.168.1.0/24 -j ACCEPT  # lockd

# Using ufw
sudo ufw allow from 192.168.1.0/24 to any port 2049 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 111 proto tcp
```

### NFS Security Best Practices Checklist

```bash
# 1. Use root_squash (it's on by default — don't disable it)
# 2. Restrict exports to specific IPs/subnets, not *
# 3. Use ro for read-only exports
# 4. Use NFSv4 (simpler, fewer daemons, smaller attack surface)
# 5. Use Kerberos (sec=krb5p) for sensitive data
# 6. Run NFSv4 only (disable v3 if possible)
# 7. Fix mountd/statd ports for firewall rules
# 8. Mount with noexec, nosuid on the client
# 9. Use all_squash for anonymous/public exports
# 10. Monitor with auditd for suspicious access
```





[← Previous](10-section-6-autofs-automatic-nfs.md) | [↑ Index](index.md) | [Next →](12-section-8-performance-tuning.md)
