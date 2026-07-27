## 💻 PRACTICE SECTION — 15 Hands-On Exercises

### Level 1 Practices: MAC Concepts and SELinux Basics

---

### ✅ Practice 1: Check Your MAC System

```bash
mkdir -p ~/linux-course/part17
cd ~/linux-course/part17

# Determine which MAC system is available
if command -v getenforce &>/dev/null; then
    echo "SELinux is available"
    echo "Mode: $(getenforce)"
    sestatus | head -5
elif command -v aa-status &>/dev/null; then
    echo "AppArmor is available"
    sudo aa-status | head -10
else
    echo "No MAC system detected"
    echo "(SELinux or AppArmor may be disabled)"
fi
```

---

### ✅ Practice 2: Check SELinux Mode and Status

```bash
cd ~/linux-course/part17

# Only on systems with SELinux
if command -v getenforce &>/dev/null; then
    echo "=== SELinux Status ==="
    sestatus
    
    echo ""
    echo "=== Current mode ==="
    getenforce
    
    echo ""
    echo "=== SELinux config file ==="
    cat /etc/selinux/config | grep -v "^#" | grep -v "^$"
fi
```

---

### Level 2 Practices: SELinux Contexts, Booleans, and AppArmor

### ✅ Practice 3: Explore File Contexts

```bash
cd ~/linux-course/part17

# Only on systems with SELinux
if command -v getenforce &>/dev/null; then
    echo "=== File contexts for /etc ==="
    ls -Z /etc/passwd /etc/shadow /etc/hosts 2>/dev/null
    
    echo ""
    echo "=== Process contexts ==="
    ps -Z -p 1 2>/dev/null
    ps -Z | head -5
    
    echo ""
    echo "=== Your context ==="
    id -Z
else
    echo "Not on SELinux system"
fi
```

---

### ✅ Practice 4: SELinux Booleans

```bash
cd ~/linux-course/part17

if command -v getenforce &>/dev/null; then
    echo "=== All booleans ==="
    getsebool -a | head -20
    
    echo ""
    echo "=== Common web booleans ==="
    getsebool -a | grep httpd | head -10
    
    echo ""
    echo "=== Boolean descriptions ==="
    sudo semanage boolean -l 2>/dev/null | grep httpd | head -5
else
    echo "Not on SELinux system"
fi
```

---

### ✅ Practice 5: Test SELinux Permissive Mode

```bash
cd ~/linux-course/part17

if command -v getenforce &>/dev/null; then
    CURRENT=$(getenforce)
    echo "Current mode: $CURRENT"
    
    # Check if we can change mode
    if [ "$CURRENT" != "Disabled" ]; then
        echo "Setting to permissive for demonstration..."
        sudo setenforce 0
        getenforce
        
        echo ""
        echo "Setting back to enforcing..."
        sudo setenforce 1
        getenforce
    else
        echo "SELinux is disabled — cannot change mode without reboot"
    fi
fi
```

---

### ✅ Practice 6: AppArmor Status

```bash
cd ~/linux-course/part17

if command -v aa-status &>/dev/null; then
    echo "=== AppArmor Status ==="
    sudo aa-status
    
    echo ""
    echo "=== Profiles directory ==="
    ls /etc/apparmor.d/ 2>/dev/null | head -20
    
    echo ""
    echo "=== Parsing a profile ==="
    if [ -f /etc/apparmor.d/usr.sbin.nginx ]; then
        head -20 /etc/apparmor.d/usr.sbin.nginx
    elif [ -f /etc/apparmor.d/usr.sbin.rsyslogd ]; then
        head -20 /etc/apparmor.d/usr.sbin.rsyslogd
    else
        ls /etc/apparmor.d/ 2>/dev/null | head -10
    fi
else
    echo "AppArmor not installed"
fi
```

---

### Level 3 Practices: Troubleshooting, Profiles, and Auditing

### ✅ Practice 7: Check SELinux Denials (if any)

```bash
cd ~/linux-course/part17

if [ -d /var/log/audit ]; then
    echo "=== Recent SELinux denials ==="
    sudo ausearch -m avc -ts recent 2>/dev/null | head -20 || \
      echo "No recent denials found"
    
    echo ""
    echo "=== Checking audit.log ==="
    sudo tail -5 /var/log/audit/audit.log 2>/dev/null | grep AVC || \
      echo "No AVC denials found"
else
    echo "No audit log directory (SELinux not active or no auditd)"
fi
```

---

### ✅ Practice 8: restorecon — Fix File Contexts

```bash
cd ~/linux-course/part17

# Create a test directory
mkdir -p /tmp/selinux-test
echo "test file" > /tmp/selinux-test/test.txt

# Check its context
ls -Z /tmp/selinux-test/test.txt

# If SELinux is active, restore the default context
if command -v restorecon &>/dev/null; then
    echo ""
    echo "Restoring context..."
    sudo restorecon -Rv /tmp/selinux-test
    ls -Z /tmp/selinux-test/test.txt
fi

# Clean up
rm -rf /tmp/selinux-test
```

---

### ✅ Practice 9: AppArmor Complain Mode

```bash
cd ~/linux-course/part17

if command -v aa-complain &>/dev/null; then
    echo "=== Checking profiles in complain mode ==="
    sudo aa-status --complaining 2>/dev/null || echo "None in complain mode"
    
    echo ""
    echo "=== Putting a profile in complain mode (example) ==="
    # Check if rsyslogd has a profile
    if [ -f /etc/apparmor.d/usr.sbin.rsyslogd ]; then
        echo "Would set: sudo aa-complain /usr/sbin/rsyslogd"
        echo "Would restore: sudo aa-enforce /usr/sbin/rsyslogd"
    fi
fi
```

---

### ✅ Practice 10: Check MAC Context After File Operations

```bash
cd ~/linux-course/part17

# Create test files
echo "original" > /tmp/mac-test-original
ls -Z /tmp/mac-test-original 2>/dev/null || echo "No SELinux context"

# Copy keeps context of destination directory
cp /tmp/mac-test-original /tmp/mac-test-copy
ls -Z /tmp/mac-test-copy 2>/dev/null || echo "No SELinux context"

# Move keeps original context
mv /tmp/mac-test-original /tmp/mac-test-moved
ls -Z /tmp/mac-test-moved 2>/dev/null || echo "No SELinux context"

# Clean up
rm -f /tmp/mac-test-*
```

---

### ✅ Practice 11: Create a Minimal AppArmor Profile

```bash
cd ~/linux-course/part17

# This is a learning exercise — not meant to be loaded
cat << 'EOF' > minimal_apparmor_profile.txt
# Minimal AppArmor profile example
# File would go to: /etc/apparmor.d/usr.local.bin.testapp

#include <tunables/global>

profile testapp /usr/local/bin/testapp {
    #include <abstractions/base>
    #include <abstractions/bash>
    
    # Allow reading config
    /etc/testapp/config r,
    
    # Allow writing logs
    /var/log/testapp/* w,
    
    # Allow network access
    network inet tcp,
    
    # Everything else denied
    deny /** w,
    deny /etc/shadow r,
}
EOF

echo "Profile template created at minimal_apparmor_profile.txt"
```

---

### ✅ Practice 12: Check SELinux Port Contexts

```bash
cd ~/linux-course/part17

if command -v semanage &>/dev/null; then
    echo "=== Port contexts ==="
    sudo semanage port -l | grep -E "ssh|http|mysql" | head -10
    
    echo ""
    echo "=== All port types ==="
    sudo semanage port -l | head -30
else
    echo "semanage not available (not on SELinux system)"
fi
```

---

### ✅ Practice 13: SELinux Troubleshooting Simulation

```bash
cd ~/linux-course/part17

# Create a simulated SELinux problem and fix
cat << 'EOF'
Simulated SELinux troubleshooting workflow:

PROBLEM: Nginx shows "Permission denied" when accessing /webroot

STEP 1: Check SELinux status
  $ getenforce
  Enforcing

STEP 2: Check file context
  $ ls -Z /webroot/
  unconfined_u:object_r:user_home_t:s0 index.html
  # Wrong context! Should be httpd_sys_content_t

STEP 3: Fix file context
  $ sudo semanage fcontext -a -t httpd_sys_content_t "/webroot(/.*)?"
  $ sudo restorecon -Rv /webroot
  $ ls -Z /webroot/
  system_u:object_r:httpd_sys_content_t:s0 index.html

STEP 4: Verify fix
  Problem solved!

ALTERNATIVE: Use restorecon directly
  $ sudo restorecon -Rv /webroot
  # Works if /webroot is already defined in the policy
EOF
```

---

### ✅ Practice 14: Check if a Specific Service is Confined

```bash
cd ~/linux-course/part17

# Check SSH daemon confinement
if command -v getenforce &>/dev/null; then
    echo "=== SSH context (SELinux) ==="
    ps -Z -C sshd 2>/dev/null || ps -Z $(pgrep -o sshd) 2>/dev/null
fi

if command -v aa-status &>/dev/null; then
    echo ""
    echo "=== SSH profile (AppArmor) ==="
    sudo aa-status | grep -i ssh
fi

echo ""
echo "=== Checking other confined processes ==="
if command -v getenforce &>/dev/null; then
    ps -Z | grep -E "nginx|httpd|mysqld|postgres|named" 2>/dev/null | head -5 || \
      echo "No confined daemons running"
fi
```

---

### ✅ Practice 15: Real SysAdmin Scenario — MAC Security Audit

```bash
cd ~/linux-course/part17

cat > mac_security_audit.sh << 'EOF'
#!/bin/bash
set -euo pipefail

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
REPORT="mac_security_report.txt"

echo "============================================" > "$REPORT"
echo "  MAC SECURITY AUDIT REPORT" >> "$REPORT"
echo "  Hostname: $HOSTNAME" >> "$REPORT"
echo "  Date:     $TIMESTAMP" >> "$REPORT"
echo "============================================" >> "$REPORT"
echo "" >> "$REPORT"

# Section 1: MAC System
echo "1. MANDATORY ACCESS CONTROL SYSTEM" >> "$REPORT"
if command -v getenforce &>/dev/null; then
    echo "  System: SELinux" >> "$REPORT"
    echo "  Mode: $(getenforce)" >> "$REPORT"
    sestatus >> "$REPORT" 2>/dev/null
elif command -v aa-status &>/dev/null; then
    echo "  System: AppArmor" >> "$REPORT"
    sudo aa-status >> "$REPORT" 2>/dev/null
else
    echo "  None detected" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 2: SELinux Booleans (if applicable)
echo "2. SELINUX BOOLEANS (non-default)" >> "$REPORT"
if command -v getsebool &>/dev/null; then
    sudo semanage boolean -l 2>/dev/null | grep -E "\(on  \-1\)|\(off  -1\)" | \
      head -20 >> "$REPORT" || echo "  No non-default booleans" >> "$REPORT"
else
    echo "  N/A" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 3: AppArmor Profiles (if applicable)
echo "3. APPARMOR PROFILES" >> "$REPORT"
if [ -d /etc/apparmor.d ]; then
    ls /etc/apparmor.d/ >> "$REPORT"
else
    echo "  N/A" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 4: Recent MAC denials
echo "4. RECENT MAC DENIALS (last 24h)" >> "$REPORT"
if [ -f /var/log/audit/audit.log ]; then
    sudo ausearch -m avc -ts today 2>/dev/null | grep -c "denied" | \
      awk '{print "  " $1 " SELinux denials today"}' >> "$REPORT" || \
      echo "  0 SELinux denials" >> "$REPORT"
elif [ -f /var/log/syslog ]; then
    grep "apparmor" /var/log/syslog 2>/dev/null | grep "DENIED" | wc -l | \
      awk '{print "  " $1 " AppArmor denials today"}' >> "$REPORT" || \
      echo "  0 AppArmor denials" >> "$REPORT"
else
    echo "  No MAC denial logs found" >> "$REPORT"
fi
echo "" >> "$REPORT"

# Section 5: Confined services
echo "5. CONFINED SERVICES" >> "$REPORT"
if command -v ps &>/dev/null; then
    ps -Z 2>/dev/null | awk 'NR>1 {print $5, $6}' | sort | uniq -c | sort -rn | head -10 >> "$REPORT" || \
      echo "  Could not retrieve" >> "$REPORT"
fi
echo "" >> "$REPORT"

echo "============================================" >> "$REPORT"
echo "  END OF REPORT" >> "$REPORT"
echo "============================================" >> "$REPORT"

cat "$REPORT"
EOF

chmod +x mac_security_audit.sh
./mac_security_audit.sh
```

---



---

[← Previous](13-section-7-selinux-vs-apparmor.md) | [↑ Index](index.md) | [Next →](15-deep-understanding-how-mac-really.md)
