## 9. Automated Compliance — OpenSCAP and Ansible

### OpenSCAP

```bash
# Install
yum install openscap-scanner scap-security-guide -y
apt install libopenscap8 scap-security-guide -y

# List available profiles
oscap info /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml | grep "Profile"

# RHEL/CentOS profiles:
#   - cis                 (CIS benchmark)
#   - cis_server_l1      (CIS Level 1)
#   - cis_server_l2      (CIS Level 2)
#   - standard            (Standard System Security)
#   - stig                (STIG for DoD)
#   - pci-dss             (PCI DSS compliance)

# Run a scan
oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis \
  --results /tmp/openscap-results.xml \
  --report /tmp/openscap-report.html \
  /usr/share/xml/scap/ssg/content/ssg-rhel8-ds.xml

# Remediate (auto-fix) — generates a script
oscap xccdf generate fix \
  --fix-type bash \
  --output /tmp/remediation.sh \
  /tmp/openscap-results.xml

# Review and apply
less /tmp/remediation.sh
# Then: bash /tmp/remediation.sh (after testing!)
```

### OpenSCAP in Cron

```bash
# Weekly scan with email
cat > /usr/local/bin/openscap-weekly.sh << 'SCRIPT'
#!/bin/bash
RESULT="/tmp/openscap-results-$(date +%Y%m%d).xml"
REPORT="/tmp/openscap-report-$(date +%Y%m%d).html"

oscap xccdf eval \
  --profile xccdf_org.ssgproject.content_profile_cis_server_l1 \
  --results "$RESULT" \
  --report "$REPORT" \
  /usr/share/xml/scap/ssg/content/ssg-$(cat /etc/os-release | grep ID | head -1 | cut -d'"' -f2)$(cat /etc/os-release | grep VERSION_ID | cut -d'"' -f2)-ds.xml 2>/dev/null

mail -s "OpenSCAP Report $(hostname)" admin@example.com < "$REPORT"
SCRIPT
chmod 700 /usr/local/bin/openscap-weekly.sh
echo "0 2 * * 0 root /usr/local/bin/openscap-weekly.sh" > /etc/cron.d/openscap-weekly
```

### Ansible Hardening Playbooks

```bash
# Install required roles
ansible-galaxy role install dev-sec.os-hardening
ansible-galaxy role install dev-sec.ssh-hardening
ansible-galaxy collection install devsec.hardening

# Playbook: full system hardening
cat > harden.yml << 'PLAYBOOK'
---
- name: System Hardening Playbook
  hosts: all
  become: true

  vars:
    # SSH hardening
    ssh_allow_groups: "wheel admin"
    ssh_max_auth_tries: 3
    ssh_permit_root_login: "no"
    ssh_x11_forwarding: "no"
    ssh_password_authentication: "no"

    # Kernel hardening
    sysctl_settings:
      net.ipv4.ip_forward: 0
      net.ipv4.conf.all.accept_redirects: 0
      net.ipv4.conf.all.send_redirects: 0
      net.ipv4.conf.all.rp_filter: 1
      kernel.randomize_va_space: 2
      kernel.dmesg_restrict: 1
      kernel.kptr_restrict: 2
      fs.suid_dumpable: 0
      fs.protected_hardlinks: 1
      fs.protected_symlinks: 1

    # Audit rules
    audit_rules: |
      -w /etc/passwd -p wa -k identity
      -w /etc/shadow -p wa -k identity
      -w /etc/sudoers -p wa -k sudoers
      -a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=4294967295 -k root_commands

  roles:
    - dev-sec.os-hardening
    - dev-sec.ssh-hardening

  tasks:
    - name: Install and configure AIDE
      apt:
        name: aide
        state: present
      when: ansible_os_family == "Debian"

    - name: Configure AIDE
      template:
        src: templates/aide.conf.j2
        dest: /etc/aide.conf
        owner: root
        group: root
        mode: '0600'

    - name: Configure fail2ban
      apt:
        name: fail2ban
        state: present

    - name: Deploy fail2ban local config
      template:
        src: templates/jail.local.j2
        dest: /etc/fail2ban/jail.local
        owner: root
        group: root
        mode: '0644'
      notify: restart fail2ban

    - name: Install Lynis
      apt:
        name: lynis
        state: present

    - name: Create AIDE daily cron
      cron:
        name: "AIDE daily check"
        hour: 5
        minute: 0
        job: "/usr/local/bin/aide-check.sh"

  handlers:
    - name: restart fail2ban
      systemd:
        name: fail2ban
        state: restarted
PLAYBOOK

# Run against all servers
ansible-playbook -i inventory.ini harden.yml --check   # Dry run first
ansible-playbook -i inventory.ini harden.yml            # Apply
```

### Compliance Verification Workflow

```
┌─────────────────────────────────────────────────────────────┐
│              COMPLIANCE VERIFICATION FLOW                     │
│                                                               │
│  1. BASELINE                                                  │
│     └─► Lynis scan → Score: 45                               │
│     └─► OpenSCAP scan → 87 failures                          │
│                                                               │
│  2. REMEDIATE                                                  │
│     └─► Ansible hardening playbook                            │
│     └─► Manual CIS fixes                                      │
│     └─► Deploy auditd rules                                   │
│                                                               │
│  3. VERIFY                                                     │
│     └─► Lynis scan → Score: 78                               │
│     └─► OpenSCAP scan → 3 failures (acceptable)              │
│     └─► AIDE initialized with clean baseline                  │
│                                                               │
│  4. MONITOR                                                    │
│     └─► Daily AIDE checks                                     │
│     └─► Weekly Lynis scans                                    │
│     └─► Monthly OpenSCAP scans                                │
│     └─► Continuous auditd monitoring                          │
│     └─► fail2ban active on all services                       │
│                                                               │
│  5. MAINTAIN                                                   │
│     └─► Update baselines after approved changes               │
│     └─► Review audit logs weekly                              │
│     └─► Re-scan after patches                                 │
│     └─► Track score trends in Grafana                         │
└─────────────────────────────────────────────────────────────┘
```

---



---

[← Previous](10-8-aide-file-integrity-monitoring.md) | [↑ Index](index.md) | [Next →](12-hands-on-practices.md)
