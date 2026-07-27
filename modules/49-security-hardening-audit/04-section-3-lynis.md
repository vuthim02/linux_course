## 🔍 Section 3: Lynis

### What Is Lynis?

**Lynis** is an open-source security auditing tool for Unix/Linux systems. It performs hundreds of individual tests, assigns a **hardening index** score, and provides actionable hardening suggestions.

### Installation

```bash
# Debian/Ubuntu
sudo apt update
sudo apt install -y lynis

# RHEL/CentOS/Fedora
sudo dnf install -y epel-release
sudo dnf install -y lynis

# From source (always latest)
git clone https://github.com/CISOfy/lynis.git /opt/lynis
sudo /opt/lynis/lynis audit system
```

### Running a Lynis Audit

```bash
# Full system audit
sudo lynis audit system

# Audit with specific category
sudo lynis audit system --tests-from-group malware,networking

# Show available test categories
sudo lynis show categories
```

### Sample Lynis Output

```
===========================================================
  Lynis 3.1.1
===========================================================
  Profile:        /etc/lynis/default.prf
  System:         Ubuntu 24.04 LTS
  Test Groups:    all
  Hardening Index: 67 [████████░░░░░░░░░░░░░░░░░░]

===========================================================
  Warnings (4):
===========================================================
  ! File system permissions on /etc/shadow are not strict [FILE-7524]
  ! No running auditing daemon detected [ACCT-9628]
  ! Passwordless sudo entries found [AUTH-9328]
  ! Kernel hardening: no dedicated kernel hardening system [KRNL-5820]

===========================================================
  Suggestions (18):
===========================================================
  * Consider hardening SSH configuration [SSH-7408]
    - Set PermitRootLogin to no
    - Set PasswordAuthentication to no
    - Set MaxAuthTries to 3
  * Install a PAM module for password strength testing [AUTH-9262]
    - Install libpam-pwquality (apt install libpam-pwquality)
  * Install a file integrity tool [FINT-4350]
    - Install AIDE (apt install aide)
  * Configure auditd to collect system events [ACCT-9622]
    - Install and enable auditd
```

### Hardening Index

The hardening index is a score from 0-100. A score below 60 indicates significant work needed; 60-80 is reasonable; 80+ is well-hardened.

```bash
# To see only the hardening index from a previous scan:
sudo lynis show details --details | grep hardening_index

# Or grep from the full output:
sudo lynis audit system | grep -i "hardening index"
```

### Custom Lynis Profiles

```bash
# Create a custom profile for your organization
sudo mkdir -p /etc/lynis
sudo tee /etc/lynis/custom.prf > /dev/null << 'EOF'
# Custom Lynis profile for Production Web Servers
profile=production-web-server

# Skip some tests that don't apply
skip-test=PRNT-2307
skip-test=PRNT-2308

# Custom mail server for reports
mailto=security@example.com

# Custom plugins
plugin=/etc/lynis/plugins/custom_plugin
EOF

# Run with custom profile
sudo lynis audit system --profile /etc/lynis/custom.prf
```

### Compliance Framework Mapping

Lynis can map findings to compliance frameworks:

```bash
# Map results to PCI-DSS
sudo lynis audit system --compliance PCI

# Map to ISO 27001
sudo lynis audit system --compliance ISO27001

# Map to HIPAA
sudo lynis audit system --compliance HIPAA
```

---



---

[← Previous](03-section-2-cis-benchmarks.md) | [↑ Index](index.md) | [Next →](05-section-4-openscap.md)
