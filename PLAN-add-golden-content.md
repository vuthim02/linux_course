# Plan: Add Golden Quotes, Tricks, Formulas & Rules to All 66 Modules

## Overview

This plan adds 4 new sections to each of the 66 modules in the Linux System Administration course:
1. **Golden Quotes** - Famous quotes from Linus Torvalds, UNIX philosophy, industry leaders
2. **Tricks & Mnemonics** - Memory aids, shortcuts, pro tips
3. **Formulas & Calculations** - Mathematical formulas for system administration
4. **Rules of Thumb** - Practical guidelines and heuristics

## Insertion Point

New sections are inserted **after Command Reference** and **before What's Coming**:

```
[Teaching sections]
       ↓
Hands-On Practices
Deep Understanding
Summary / Command Reference
       ↓  ← INSERTION POINT
Golden Quotes        (NEW)
Tricks & Mnemonics   (NEW)
Formulas & Calculations (NEW)
Rules of Thumb       (NEW)
       ↓
What's Coming in Part N+1
Self Test
```

## File Naming Convention

Each module gets 4 new files:
```
NN-golden-quotes.md
NN-tricks-and-mnemonics.md
NN-formulas-and-calculations.md
NN-rules-of-thumb.md
```

## Implementation Strategy

### Phase 1: Foundation Modules (01-15)

| Module | Golden Quotes | Tricks/Mnemonics | Formulas | Rules of Thumb |
|--------|---------------|------------------|----------|----------------|
| 01-what-is-linux | "Everything is a file" - Thompson | "One tree, not a forest" | N/A | Learn concepts, not commands |
| 02-terminal | "Linux is one tree" | LHTR = Long,Human,Time,Reverse | N/A | ls -ltr for recent files |
| 03-users-groups-permissions | "Permissions are Linux's immune system" | UGO = User,Group,Others | r=4,w=2,x=1 | Never use 777 |
| 04-text-editors | "Vim is not an editor, it's a lifestyle" | ESC-WQ = Write-Quit | N/A | Always use vim |
| 05-pipes-redirection | "Pipes are Unix's assembly line" | 0=stdin,1=stdout,2=stderr | N/A | Think before overwriting |
| 06-shell-scripting | "Script once, automate forever" | set -euo pipefail | N/A | Quote variables |
| 07-finding-things | "grep searches what files say" | IRC-VL for grep options | find mtime math | Preview before delete |
| 08-archiving-compression | "tar is tape archiver" | czf = Compress,Ze,File | N/A | Always test archives |
| 09-process-management | "SIGTERM asks, SIGKILL kicks" | 1-9-15 = HUP,KILL,TERM | Load < cores = healthy | Try graceful first |
| 10-linux-boot-process | "BIOS→GRUB→Kernel→systemd" | PBGSL = Power,BIOS,GRUB,systemd,Login | N/A | Never edit grub.cfg |
| 11-package-management | "apt is the librarian" | Debian=apt=.deb | N/A | Update lists first |
| 12-systemd-services | "systemd is PID 1" | service = unit file | N/A | systemctl daemon-reload |
| 13-scheduling-tasks | "cron is the timekeeper" | min hour dom mon dow | N/A | Test crontab entries |
| 14-logging-journald | "Logs are the black box" | journalctl -f = follow | N/A | Check logs first |
| 15-ssh-remote-access | "SSH is teleportation" | 700-600-644 = dir,private,pub | N/A | Use key-based auth |

### Phase 2: Intermediate Modules (16-35)

| Module | Golden Quotes | Tricks/Mnemonics | Formulas | Rules of Thumb |
|--------|---------------|------------------|----------|----------------|
| 16-firewalls | "Every port is an open door" | iptables: INPUT,FORWARD,OUTPUT | N/A | Default deny |
| 17-selinux-apparmor | "SELinux is not the enemy" | sestatus, getenforce | N/A | Check SELinux first |
| 18-environment-variables | "PATH is the shell's map" | E-B-R = profile,bashrc | N/A | Bashrc=bashprofile=identity |
| 19-software-repositories | "Repositories are app stores" | sources.list format | N/A | Verify GPG keys |
| 20-system-updates-patch | "Updates are immunizations" | apt update → upgrade | N/A | Test in staging |
| 21-time-synchronization | "Time is the invisible glue" | NTP offset formula | ((T2-T1)+(T3-T4))/2 | Kerberos = 5 min |
| 22-network-services | "Services are daemons" | systemctl status service | N/A | Check firewall |
| 23-virtual-terminals | "TTY is your window" | Ctrl+Alt+F1-F6 | N/A | Alt+F7 = GUI |
| 24-kernel-modules | "Modules are kernel Lego" | modprobe=smart,insmod=dumb | N/A | Prefer modprobe |
| 25-system-rescue-recovery | "Rescue mode is ER" | single/init=/bin/bash | N/A | Always have live USB |
| 26-network-configuration | "ip is the new ifconfig" | ip addr,ip link,ip route | N/A | Check carrier first |
| 27-dns-name-resolution | "DNS is the internet's phonebook" | ACMENST = record types | N/A | dig lies about hosts |
| 28-nfs | "NFS is Unix file sharing" | RPC program numbers | N/A | Lock ports for firewall |
| 29-samba-windows | "Samba speaks Windows" | workgroup vs domain | N/A | Test with testparm |
| 30-raid | "RAID is not backup" | 0=zero,1=copy,5=parity | (N-1) for RAID 5 | RAID 10 for databases |
| 31-lvm | "LVM is storage elasticity" | PV→VG→LV | LV = sum of PVs | Resize online |
| 32-backup-strategies | "Backup is insurance" | 3-2-1 rule | RPO/RTO formulas | Test restores |
| 33-system-monitoring | "You can't fix what you can't see" | R-B-SI-SO-WA = alarm cols | Load < cores | Swap = 1000x slower |
| 34-process-management-advanced | "Processes are programs alive" | /proc/PID/ files | N/A | Check /proc first |
| 35-shell-scripting-admin | "Automate or die" | trap, set -euo pipefail | N/A | Log everything |

### Phase 3: Advanced Modules (36-55)

| Module | Golden Quotes | Tricks/Mnemonics | Formulas | Rules of Thumb |
|--------|---------------|------------------|----------|----------------|
| 36-advanced-shell-scripting | "sed transforms, awk thinks" | NR-NF-FS = awk vars | N/A | Test before -i |
| 37-ansible | "Ansible is agentless" | YAML: tasks,handlers,vars | N/A | idempotency |
| 38-container-basics | "Containers are namespaces" | PID,NET,MNT namespaces | N/A | One process per container |
| 39-web-servers | "Nginx is the traffic cop" | location block priority | N/A | Check error logs |
| 40-databases | "ACID is the contract" | Buffer pool = 70-80% RAM | Hit rate formula | Test restores |
| 41-ldap-centralized-auth | "LDAP is the phonebook" | cn,ou,dc hierarchy | N/A | Use ldaps |
| 42-dns-server-bind | "BIND is DNS" | zone file syntax | SOA serial format | named-checkconf |
| 43-dhcp-server | "DORA the Explorer" | DORA = Discover,Offer,Request,ACK | N/A | Always test config |
| 44-mail-servers | "Mail is SMTP+IMAP" | MX priority | N/A | Check spam filters |
| 45-proxy-reverse-proxy | "Proxy is the middleman" | upstream block | N/A | Health checks |
| 46-monitoring-alerting | "Four golden signals" | rate() for alerts | PromQL formulas | Record rules |
| 47-performance-tuning | "USE method" | Utilization,Saturation,Errors | I/O formulas | Measure first |
| 48-high-availability-clustering | "HA is redundancy" | STONITH/Fencing | Failover time | Test failover |
| 49-security-hardening-audit | "Defense in depth" | CIA = Confidentiality,Integrity,Availability | N/A | Layer controls |
| 50-cloud-infrastructure | "Cloud is someone else's computer" | VPC,subnets,security groups | N/A | Tag everything |
| 51-infrastructure-as-code | "IaC is reproducibility" | terraform plan/apply | N/A | State file backup |
| 52-kubernetes | "K8s is the cloud OS" | ECAS = control plane | CrashLoopBackOff backoff | Check logs --previous |
| 53-cicd-pipelines | "CI/CD is the factory" | pipeline stages | N/A | Test in parallel |
| 54-config-management | "CM is consistency" | declarative vs imperative | N/A | Agent vs agentless |
| 55-immutable-infrastructure | "Immutable = no SSH" | golden image pattern | N/A | Never patch, rebuild |

### Phase 4: Expert Modules (56-66)

| Module | Golden Quotes | Tricks/Mnemonics | Formulas | Rules of Thumb |
|--------|---------------|------------------|----------|----------------|
| 56-observability | "Observability = monitoring + tracing + logging" | RED/USE method | SLO error budget | Multi-window alerts |
| 57-modern-networking | "Networking is layers" | OSI 7 layers | Throughput formulas | Check MTU |
| 58-secrets-management | "Secrets are poison" | Vault: auth,secret,policy | N/A | Rotate secrets |
| 59-sre | "SRE isOps done right" | SLI/SLO/SLA | Error budget = 1-SLO | Blameless postmortems |
| 60-capstone | "Production is reality" | Full stack architecture | All formulas | Test everything |
| 61-filesystem-internals | "Filesystem is the foundation" | inode, superblock, journal | df vs du formula | fsck as last resort |
| 62-memory-management | "Memory is oxygen" | /proc/meminfo fields | OOM score formula | Swap = emergency |
| 63-ebpf-tracing | "eBPF is kernel scripting" | probe types: kprobe,tracepoint | N/A | Filter events |
| 64-linux-namespaces | "Namespaces are containers" | PID,NET,MNT,UTS,IPC,USER | N/A | One namespace per resource |
| 65-pam-centralized-auth | "PAM is the bouncer" | auth,account,session,password | N/A | Faillock > tally |
| 66-system-hardening | "Hardening is layering" | CIS Level 1 vs 2 | N/A | Audit regularly |

## Content Format

### Golden Quotes Section Template

```markdown
## Golden Quotes

> "Quote text here."
> — **Person Name**, *Source/Context*

> "Another quote."
> — **Person Name**, *Source/Context*

**Why this matters:** Brief explanation of how the quote relates to this module.
```

### Tricks & Mnemonics Section Template

```markdown
## Tricks & Mnemonics

### Memory Aids
- **Mnemonic:** Description
- **Acronym:** What it stands for

### Pro Tips
1. **Tip title:** Description
2. **Tip title:** Description

### Shortcuts
| Shortcut | What it does |
|----------|--------------|
| ... | ... |
```

### Formulas & Calculations Section Template

```markdown
## Formulas & Calculations

### Formula Name
```
formula = variable1 + variable2
```

**Where:**
- variable1 = description
- variable2 = description

**Example:**
```
calculation with real numbers
```

**Rule of thumb:** practical guideline
```

### Rules of Thumb Section Template

```markdown
## Rules of Thumb

### Rule 1: Title
Description of the rule and when to apply it.

### Rule 2: Title
Description of the rule and when to apply it.

### Quick Reference
| Situation | Rule |
|-----------|------|
| ... | ... |
```

## Implementation Order

1. **Phase 1 (Modules 01-15):** Foundation - basic Linux concepts
2. **Phase 2 (Modules 16-35):** Intermediate - system administration
3. **Phase 3 (Modules 36-55):** Advanced - servers and applications
4. **Phase 4 (Modules 56-66):** Expert - advanced topics

## Estimated Total Files

- 66 modules × 4 new files = **264 new files**
- Each file approximately 50-100 lines
- Total new content: ~15,000-25,000 lines

## Quality Checklist

For each module, verify:
- [ ] Golden quotes are accurate and attributed correctly
- [ ] Mnemonics are memorable and accurate
- [ ] Formulas are mathematically correct
- [ ] Rules of thumb are practical and tested
- [ ] Content matches the module's difficulty level
- [ ] Index.md is updated with new sections
- [ ] File numbering is sequential
- [ ] Cross-references between modules are correct
