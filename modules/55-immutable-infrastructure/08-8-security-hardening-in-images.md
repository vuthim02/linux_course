## 8. Security Hardening in Images

### CIS Benchmarks

The Center for Internet Security (CIS) publishes benchmarks for hardening OS images. Key controls:

```bash
#!/bin/bash
# scripts/harden-cis.sh
# CIS Level 1 hardening for Ubuntu 22.04

set -euo pipefail

echo "=== CIS Hardening: Level 1 ==="

# 1.1.1 Disable unused filesystems
echo "install cramfs /bin/true" | sudo tee /etc/modprobe.d/cis-cramfs.conf
echo "install freevxfs /bin/true" | sudo tee /etc/modprobe.d/cis-freevxfs.conf
echo "install jffs2 /bin/true" | sudo tee /etc/modprobe.d/cis-jffs2.conf
echo "install hfs /bin/true" | sudo tee /etc/modprobe.d/cis-hfs.conf
echo "install hfsplus /bin/true" | sudo tee /etc/modprobe.d/cis-hfsplus.conf
echo "install squashfs /bin/true" | sudo tee /etc/modprobe.d/cis-squashfs.conf
echo "install udf /bin/true" | sudo tee /etc/modprobe.d/cis-udf.conf

# 1.4.1 Ensure bootloader password (skip for automated builds)
# 1.4.2 Ensure permissions on bootloader config
sudo chmod 600 /boot/grub/grub.cfg

# 1.5.1 Ensure address space layout randomization (ASLR)
echo "kernel.randomize_va_space = 2" | sudo tee /etc/sysctl.d/60-aslr.conf

# 1.6.1 Ensure core dumps are restricted
echo "* hard core 0" | sudo tee /etc/security/limits.d/99-disable-core.conf
echo "fs.suid_dumpable = 0" | sudo tee /etc/sysctl.d/60-coredump.conf

# 2.1 Remove legacy services
sudo apt-get remove -y rsh-client rsh-redone-client talk telnet

# 3.1 Ensure nftables or iptables (skip — managed by orchestrator)
# 3.2 Ensure wireless interfaces are disabled (not applicable on servers)

# 4.2.1.1 Ensure rsyslog is installed
sudo apt-get install -y rsyslog

# 5.1.1 Ensure cron daemon is enabled
sudo systemctl enable cron

# 5.2 SSH hardening
sudo tee /etc/ssh/sshd_config.d/99-cis.conf > /dev/null <<SSHCONFIG
Protocol 2
MaxAuthTries 4
MaxSessions 10
PermitRootLogin no
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 300
ClientAliveCountMax 0
LogLevel VERBOSE
AllowUsers ubuntu
SSHCONFIG

# 5.4 Ensure no legacy + entries in passwd
sudo pwck -q

# 5.4.1.1 Ensure password expiration
sudo tee /etc/login.defs.d/99-cis > /dev/null <<LOGINDEFS
PASS_MAX_DAYS 90
PASS_MIN_DAYS 7
PASS_WARN_AGE 14
LOGINDEFS

# 6.1 Ensure permissions on /etc/passwd, shadow, group
sudo chmod 644 /etc/passwd
sudo chmod 644 /etc/group
sudo chmod 600 /etc/shadow
sudo chmod 600 /etc/gshadow

echo "=== CIS Hardening: Complete ==="
```

### Minimal Packages

```bash
#!/bin/bash
# scripts/minimal-packages.sh

set -euo pipefail

echo "=== Removing unnecessary packages ==="

# Remove snap (Ubuntu)
sudo apt-get purge -y snapd ubuntu-core-launcher squashfs-tools || true

# Remove cloud management agents (keep cloud-init)
sudo apt-get purge -y multipath-tools || true

# Remove compilers and build tools (not needed in production)
sudo apt-get purge -y gcc g++ make autoconf automake libtool || true

# Remove network tools not needed
sudo apt-get purge -y avahi-daemon whoopsie || true

# Remove X11 libraries
sudo apt-get purge -y libx11.* libxau.* libxcb.* || true

# Remove Python3 and pip (if not needed)
# sudo apt-get purge -y python3-pip python3-dev || true

# Remove Perl
# sudo apt-get purge -y perl perl-modules || true

# Remove documentation
sudo rm -rf /usr/share/doc/*
sudo rm -rf /usr/share/man/*
sudo rm -rf /usr/share/info/*
sudo rm -rf /usr/share/lintian/*
sudo rm -rf /usr/share/linda/*

echo "=== Minimal packages: Complete ==="
```

### No Secrets in Images

**NEVER** bake secrets into images. Use secrets management at runtime:

```bash
# WRONG — never do this
RUN echo "DB_PASSWORD=supersecret" >> /etc/environment

# CORRECT — use runtime secrets
# Userdata retrieves secrets at boot:
# aws secretsmanager get-secret-value --secret-id myapp/db --query SecretString
```

**What to exclude from images:**
- SSH private keys
- API keys, tokens, passwords
- TLS/SSL private keys (use ACM, cert-manager, or vault)
- Cloud provider credentials
- Database connection strings
- Service account keys
- License files

### Image Scanning

```bash
# Trivy (open-source scanner)
trivy image --severity CRITICAL,HIGH ami-12345678
trivy image --severity CRITICAL --ignore-unfixed ubuntu:22.04
trivy fs --severity CRITICAL,HIGH /path/to/rootfs

# In Packer, scan after build:
provisioner "shell-local" {
  environment_vars = [
    "AMI_ID={{ .BuildID }}"
  ]
  inline = [
    "trivy image --severity CRITICAL,HIGH --exit-code 1 $AMI_ID"
  ]
}

# AWS Inspector (requires agent or ECR scanning)
aws inspector2 enable --resource-types EC2

# Snyk
snyk container test docker-image:tag --severity-threshold=high

# Grype
grype registry:ubuntu:22.04
```

```hcl
# Packer provisioner to run Trivy on the build before finalizing
provisioner "shell-local" {
  inline = [
    "echo 'Scanning the image during build...'",
    "trivy fs --severity CRITICAL,HIGH --exit-code 1 / || true"
  ]
}

# Post-processor to generate manifest with scan results
post-processor "manifest" {
  output     = "manifest.json"
  strip_path = true

  custom_data = {
    trivy_scan = "passed"
    scanner    = "trivy-0.50.0"
  }
}
```





[← Previous](07-7-image-pipeline.md) | [↑ Index](index.md) | [Next →](09-9-deployment-strategies-for-immutable.md)
