## 2. CIS Benchmarks — The Security Playbook

### What Are CIS Benchmarks?

The Center for Internet Security publishes vendor-specific hardening guides. Each benchmark contains hundreds of numbered rules, each with:

- **Description** — what the setting does
- **Rationale** — why it matters
- **Audit** — how to check compliance
- **Remediation** — how to fix non-compliance

### CIS Benchmark Levels

```
┌──────────────────────────────────────────────────┐
│              CIS BENCHMARK LEVELS                  │
├──────────────────────────────────────────────────┤
│                                                    │
│  Level I (Minimum Hygiene)                         │
│  ├─ Basic security controls                        │
│  ├─ Low risk of functionality impact               │
│  └─ Suitable for all systems                       │
│                                                    │
│  Level II (Defense in Depth)                       │
│  ├─ Additional controls for sensitive systems      │
│  ├─ May require additional testing                │
│  └─ Recommended for servers                        │
│                                                    │
│  Level III (High Security / Defense Only)          │
│  ├─ Maximum hardening                              │
│  ├─ May break applications                         │
│  └─ For high-security / classified systems         │
│                                                    │
└──────────────────────────────────────────────────┘
```

### Applying CIS Benchmarks Manually (Key Items)

```bash
# === CIS Item 1.1.1.1 — Disable unused filesystems ===
echo "install cramfs /bin/true" >> /etc/modprobe.d/disable-fs.conf
echo "install freevxfs /bin/true" >> /etc/modprobe.d/disable-fs.conf
echo "install udf /bin/true" >> /etc/modprobe.d/disable-fs.conf

# === CIS Item 1.1.1.4 — Disable USB storage ===
echo "install usb-storage /bin/true" >> /etc/modprobe.d/disable-fs.conf

# === CIS Item 1.3.1 — Ensure AIDE is installed ===
apt install aide -y    # or: yum install aide -y

# === CIS Item 3.1.1 — Disable IP forwarding (non-router) ===
sysctl -w net.ipv4.ip_forward=0
echo "net.ipv4.ip_forward = 0" >> /etc/sysctl.d/99-cis.conf

# === CIS Item 3.2.1 — Disable source routing ===
sysctl -w net.ipv4.conf.all.accept_source_route=0
sysctl -w net.ipv4.conf.default.accept_source_route=0

# === CIS Item 4.1.1 — Ensure auditing is enabled (audit=1) ===
grep -q "audit=1" /etc/default/grub || \
  sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="audit=1"/' /etc/default/grub
update-grub

# === CIS Item 5.2.4 — SSH: Set idle timeout ===
echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config

# === CIS Item 5.2.10 — SSH: Disable X11 forwarding ===
echo "X11Forwarding no" >> /etc/ssh/sshd_config

# === CIS Item 5.4.1 — Set password expiration ===
sed -i 's/^PASS_MAX_DAYS.*/PASS_MAX_DAYS   90/' /etc/login.defs
sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   7/'  /etc/login.defs
sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   14/' /etc/login.defs
```

> ⚠️ **Warning:** Always test CIS changes on a staging system first. Some settings (like disabling filesystems or tightening SSH) can lock you out or break applications.

### Automated CIS Hardening with Scripts

```bash
# Download CIS-CAT (free scanner from CIS)
# or use OpenSCAP with CIS profiles (covered in Section 9)

# Using Ansible CIS role (popular community approach)
ansible-galaxy role install dev-sec.os-hardening

# In playbook:
# - role: dev-sec.os-hardening
#   vars:
#     os_auth_pw_max_age: 90
#     os_auth_pw_min_age: 7
#     os_auth_pw_remember_password: 5
```

### CIS Audit with OpenSCAP

```bash
# Install OpenSCAP
apt install libopenscap8 scap-security-guide -y   # Ubuntu
yum install openscap-scap-security-guide -y         # RHEL

# Scan against CIS benchmark
oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
  --results /tmp/cis-results.xml \
  --report /tmp/cis-report.html \
  /usr/share/xml/scap/ssg/content/ssg-ubuntu2204-ds.xml

# View results
echo "Open /tmp/cis-report.html in a browser"
```





[← Previous](02-1-defense-in-depth-the.md) | [↑ Index](index.md) | [Next →](04-3-kernel-hardening-sysctl-and.md)
