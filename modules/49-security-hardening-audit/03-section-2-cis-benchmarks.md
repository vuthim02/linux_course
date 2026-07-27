## 🔍 Section 2: CIS Benchmarks

### What Are CIS Benchmarks?

The **Center for Internet Security (CIS)** publishes hardening guidelines for OS, cloud, network devices, and applications. Each benchmark provides:

- **Configuration recommendations** organized by section
- **Level 1** — Essential hardening that does not reduce functionality
- **Level 2** — More restrictive hardening suitable for high-security environments
- **Automated assessment tools** to check compliance

### CIS-CAT Tool

CIS provides the **CIS-CAT Pro** assessment tool (paid license for full version, free Lite version available):

```bash
# CIS-CAT Lite (normally runs via Java)
java -jar CIS-CAT-Lite.jar \
  --profile "Level 1" \
  --benchmark "CIS_Ubuntu_Linux_20.04_LTS_Benchmark_v1.0.0.xml" \
  --output-dir /root/cis-report
```

### Manual CIS Checking Examples

```bash
# CIS 1.1.1 — Ensure mounting of unused filesystems is disabled
sudo modprobe -r crampfs freevxfs jffs2 hfs hfsplus squashfs udf

# CIS 1.1.8 — Ensure nodev option on /dev/shm
mount -o remount,nodev,nosuid,noexec /dev/shm

# CIS 4.1.1 — Ensure auditd is installed and enabled
sudo apt install -y auditd audispd-plugins
sudo systemctl enable --now auditd
```

### Automated Compliance Checking with OpenSCAP

While CIS-CAT is proprietary, **OpenSCAP** (Section 3) can check many CIS rules for free:

```bash
# RHEL/CentOS — scan against CIS profile
sudo oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis \
  --results scan-results.xml \
  --report scan-report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml
```

---



---

[← Previous](02-section-1-security-philosophy.md) | [↑ Index](index.md) | [Next →](04-section-3-lynis.md)
