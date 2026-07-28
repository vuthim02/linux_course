## 2. PAM Configuration — `/etc/pam.d/`

### Directory Structure

```bash
# PAM configuration directory
ls /etc/pam.d/

# Typical contents on RHEL/Fedora:
# chsh  fingerprint-auth  login       password-auth  runuser    sssd-shadowutils
# chfn  fingerprint-auth-ac  polkit-1  runuser-l    smartcard-auth
# cockpit  login  postlogin  remote  sshd  su  sudo  sudo-i  system-auth

# On Debian/Ubuntu:
# common-auth  common-password  common-session  common-session-noninteractive
# login  sshd  su  sudo  polkit-1
```

### Configuration File Format

Each line in a PAM config file follows this format:

```
<module_type>  <control_flag>  <module_path>  [module_arguments...]
```

### The Four Module Types

```
┌──────────────────────────────────────────────────────────┐
│  MODULE TYPE    │  PURPOSE                                │
├──────────────────────────────────────────────────────────┤
│  auth           │  Verify the user's identity            │
│                 │  (password, biometric, token)           │
├──────────────────────────────────────────────────────────┤
│  account        │  Check if the account is valid         │
│                 │  (expired, locked, allowed time)        │
├──────────────────────────────────────────────────────────┤
│  password       │  Handle password changes               │
│                 │  (complexity, aging, history)           │
├──────────────────────────────────────────────────────────┤
│  session        │  Set up / tear down user session        │
│                 │  (limits, umask, home dir, logging)     │
└──────────────────────────────────────────────────────────┘
```

### Control Flags — How PAM Chains Results

```
┌──────────────────────────────────────────────────────────┐
│  CONTROL FLAG  │  BEHAVIOR                                │
├──────────────────────────────────────────────────────────┤
│  required       │  Must pass. If fails, continue checking │
│                 │  but最终 result is always failure.       │
│                 │  Failure message delayed to prevent     │
│                 │  user enumeration.                       │
├──────────────────────────────────────────────────────────┤
│  requisite      │  Must pass. If fails, IMMEDIATELY       │
│                 │  return failure. No further checks.     │
├──────────────────────────────────────────────────────────┤
│  sufficient     │  If passes AND no prior required has    │
│                 │  failed, return success immediately.    │
│                 │  If fails, ignore and continue.         │
├──────────────────────────────────────────────────────────┤
│  optional       │  Success doesn't matter unless it's    │
│                 │  the ONLY module of that type.          │
├──────────────────────────────────────────────────────────┤
│  include        │  Include another PAM config file        │
├──────────────────────────────────────────────────────────┤
│  substack       │  Like include, but count failures      │
│                 │  as one module.                          │
├──────────────────────────────────────────────────────────┤
│  requisite      │  Immediate failure return               │
│  (advanced)     │  Use "syntax=value" to specify action   │
│                 │  on failure: [success=done new_authtok...│
└──────────────────────────────────────────────────────────┘
```

### Example: RHEL `/etc/pam.d/system-auth`

```bash
#%PAM-1.0
# This file is auto-generated.
# User changes will be destroyed the next time authselect is run.

auth        required      pam_env.so
auth        required      pam_faillock.so preauth silent audit deny=5 unlock_time=900
auth        sufficient    pam_unix.so nullok try_first_pass
auth        [default=die] pam_faillock.so authfail audit deny=5 unlock_time=900
auth        sufficient    pam_sss.so forward_pass
auth        required      pam_deny.so

account     required      pam_unix.so
account     sufficient    pam_localuser.so
account     sufficient    pam_sss.so
account     required      pam_permit.so

password    requisite     pam_pwquality.so local_users_only retry=3
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
password    sufficient    pam_sss.so use_authtok
password    required      pam_deny.so

session     required      pam_limits.so
session     required      pam_namespace.so
session     optional      pam_oddjob_mkhomedir.so skel=/etc/skel umask=077
session     optional      pam_sss.so
session     required      pam_unix.so
```

> ⚠️ **Warning:** Never hand-edit PAM configuration files on RHEL/Fedora — they are managed by `authselect`. Manual edits will be overwritten. Use `authselect` profiles and custom features instead (covered in Section 7).

### Example: Debian `/etc/pam.d/common-auth`

```bash
# /etc/pam.d/common-auth
auth    [success=2 default=ignore]      pam_unix.so nullok
auth    [success=1 default=ignore]      pam_sss.so use_first_pass
auth    requisite                       pam_deny.so
auth    required                        pam_permit.so
```

### Service-to-Config Mapping

When `sshd` calls `pam_authenticate()`, PAM reads `/etc/pam.d/sshd`. The mapping is simple:

```
Application binary name → /etc/pam.d/<name>

sshd    → /etc/pam.d/sshd
login   → /etc/pam.d/login
sudo    → /etc/pam.d/sudo
su      → /etc/pam.d/su
passwd  → /etc/pam.d/passwd
```

> 🔍 **Reverse Engineering Insight:** `pam_authenticate()` takes a service name as its first argument. The application passes its own name (e.g., "sshd"), which tells PAM which config file to read. This is why the binary name matters — renaming `ssd` would break its PAM config lookup.





[← Previous](02-1-what-is-pam-pluggable.md) | [↑ Index](index.md) | [Next →](04-3-pam-modules-deep-dive.md)
