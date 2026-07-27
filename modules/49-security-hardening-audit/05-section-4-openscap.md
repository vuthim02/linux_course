## 🔍 Section 4: OpenSCAP

### What Is SCAP?

**SCAP** (Security Content Automation Protocol) is a U.S. government standard for expressing security checklists, vulnerabilities, and compliance data. **OpenSCAP** is the open-source implementation.

### SCAP Components

| Component | Purpose | File Extension |
|-----------|---------|----------------|
| **XCCDF** | Checklist/benchmark format (what to check) | `.xml` |
| **OVAL** | Language for defining system state checks | `.xml` |
| **CPE** | Platform identification (what OS/software) | `.dict` |
| **CVE** | Common Vulnerabilities and Exposures | NVD database |

### Installation

```bash
# Debian/Ubuntu
sudo apt install -y openscap-scanner scap-workbench

# RHEL/CentOS/Fedora
sudo dnf install -y openscap-scanner scap-workbench
```

### Available Security Profiles

```bash
# List available profiles on RHEL/CentOS
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml

# Example profiles:
#   - cis_level1_server    (CIS Level 1)
#   - cis_level2_server    (CIS Level 2)
#   - pci-dss              (PCI Data Security Standard)
#   - stig                 (US DoD STIG)
#   - hipaa                (HIPAA)
#   - ospp                 (Common Criteria)
```

### Running an OpenSCAP Scan

```bash
# Create output directory
mkdir -p ~/scap-results

# Run scan with CIS Level 1 profile (RHEL)
sudo oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
  --results ~/scap-results/scan-results.xml \
  --report ~/scap-results/scan-report.html \
  --oval-results \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml

# For Ubuntu, use the DISA STIG or Ubuntu-specific content
sudo apt install -y ssg-base ssg-debian ssg-debderived
oscap info /usr/share/xml/scap/ssg/content/ssg-ubuntu2404-ds.xml
```

### OpenSCAP Remediation

OpenSCAP can automatically remediate some findings:

```bash
# Generate a fix script
sudo oscap xccdf generate fix \
  --profile xccdf_org.ssgproject.content_profile_cis_level1_server \
  --fix-type bash \
  --output ~/scap-results/remediation.sh \
  /usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml

# Review the script carefully, then run
sudo bash ~/scap-results/remediation.sh
```

### Using scap-workbench (GUI)

```bash
# Launch the graphical workbench
scap-workbench &

# 1. Open a SCAP content file (.xml)
# 2. Select a profile
# 3. Click "Scan" → runs locally
# 4. Click "Remediate" → applies fixes
```

### Understanding oscap Command Structure

```bash
# Generic structure:
oscap [module] [operation] [options] [input_file]

# Examples:
oscap xccdf eval --profile cis --results results.xml --report report.html scap-content.xml
oscap oval eval --results oval-results.xml oval-definitions.xml
oscap cpe scan cpe-dict.xml
```

---



---

[← Previous](04-section-3-lynis.md) | [↑ Index](index.md) | [Next →](06-section-5-auditd-linux-audit.md)
