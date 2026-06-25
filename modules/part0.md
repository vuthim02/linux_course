# 🐧 Linux System Administrator — Complete Course
## Part 0 of ∞: The Master Plan — Your Roadmap to Becoming a Linux SysAdmin

---

> **Course Philosophy:** This is not a "watch and forget" course. This is a **transformation program**. By the end, you will think like a sysadmin, debug like a sysadmin, and automate like a sysadmin. Part 0 is your map — read it once, then refer back whenever you feel lost.

---

## 🎯 What You Will Achieve by the End of This Course

By the time you finish, you will be able to:

- **Install, configure, and maintain** any Linux server (Ubuntu, Debian, RHEL, CentOS)
- **Manage users, groups, permissions, and security** across multi-user systems
- **Automate everything** with shell scripts, cron jobs, and systemd services
- **Troubleshoot** any system problem using logs, process monitoring, and debugging tools
- **Secure** a Linux system against common attacks (firewalls, SSH hardening, SELinux/AppArmor)
- **Manage storage** — partitions, LVM, RAID, filesystems, mounting, and disk quotas
- **Deploy and manage** web servers (Nginx/Apache), databases (MySQL/PostgreSQL), and containers (Docker/Podman)
- **Monitor performance** — CPU, memory, disk I/O, network — and fix bottlenecks
- **Understand the kernel** well enough to tune parameters and compile modules
- **Pass any Linux sysadmin interview** with confidence

---

## 🧭 The Entire Course Roadmap

**Structured as 3 progressive levels, spanning 6 phases:**

```
┌─────────────────────────────────────────────────────────────────┐
│                    PART 0 — THE MASTER PLAN                     │
│              (You are here — read this first)                   │
└─────────────────────────────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
│ 🟢 LEVEL 1: BASIC │ │ 🟡 LEVEL 2:       │ │ 🟡 LEVEL 2:       │
│   FOUNDATION      │ │   INTERMEDIARY     │ │   INTERMEDIARY    │
│   Parts 1-10      │ │   ESSENTIAL OPS   │ │   STORAGE & Fs    │
│                   │ │   Parts 11-25     │ │   Parts 26-35     │
│ • What is Linux   │ │ • Processes/tasks │ │ • Disk management │
│ • Terminal mastery│ │ • Package mgmt    │ │ • LVM & RAID      │
│ • Users/permissions│ │ • Systemd & boot │ │ • Filesystems     │
│ • Text editors    │ │ • Cron & logging  │ │ • Network fs      │
│ • Pipes & streams │ │ • SSH & remote    │ │ • Backup & rsync  │
│ • Shell scripting │ │ • Firewall/SELinux│ │ • Disk quotas     │
└───────────────────┘ └───────────────────┘ └───────────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                ▼
┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐
│ 🟡 LEVEL 2:       │ │ 🔴 LEVEL 3:       │ │ 🔴 LEVEL 3:       │
│   INTERMEDIARY    │ │   ADVANCED        │ │   ADVANCED        │
│   NETWORKING      │ │   SERVERS & APPS  │ │   ADVANCED TOPICS │
│   Parts 36-45     │ │   Parts 46-55     │ │   Parts 56+       │
│                   │ │                   │ │                   │
│ • TCP/IP & DNS    │ │ • Web servers     │ │ • Kernel tuning   │
│ • Routing & NAT   │ │ • Databases       │ │ • Compilation     │
│ • DHCP & NTP      │ │ • Docker/Podman   │ │ • Performance     │
│ • Network bonding  │ │ • Monitoring      │ │ • Security deep   │
│ • VPN & tunneling  │ │ • CI/CD basics   │ │ • Automation      │
│ • Packet analysis  │ │ • Git & deploy   │ │ • Interview prep  │
└───────────────────┘ └───────────────────┘ └───────────────────┘
```

Every part builds on the previous. **Do not skip** unless you can pass the self-test.

---

## 🧠 The Reverse Engineering Method — How This Course Works

Most courses teach: *"Here is a command, memorize it."*

This course teaches: *"Here is a problem, figure it out, then understand the command."*

### The 4-Step Learning Loop

```
┌─────────────────────────────────────────────────────┐
│                                                       │
│  1. OBSERVE                                           │
│     ├─ Read the concept (why does this exist?)        │
│     └─ See the real-world output (what does it show?) │
│                                                       │
│  2. EXPERIMENT                                        │
│     ├─ Type the commands yourself (no copy-paste)     │
│     └─ Try variations (what happens if I change X?)   │
│                                                       │
│  3. UNDERSTAND                                        │
│     ├─ Read the "Deep Understanding" section          │
│     └─ Connect it to what you already know            │
│                                                       │
│  4. PROVE                                             │
│     ├─ Complete the hands-on practices                │
│     └─ Pass the self-test before moving on            │
│                                                       │
└─────────────────────────────────────────────────────┘
```

> 💡 **The golden rule:** If you cannot explain it in your own words, you haven't learned it yet. Go back to step 2.

---

## 🛠️ What You Need Before Starting

### Hardware Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **CPU** | Any x86_64 processor | 4+ cores |
| **RAM** | 2 GB | 8+ GB |
| **Disk** | 20 GB free | 50+ GB free |
| **Internet** | Required for package downloads | Broadband |

### You Have Two Setup Options

#### Option A: Install Linux Natively (Best)
Install Ubuntu or Fedora as your main OS. You will learn 10x faster when Linux is your daily driver.

#### Option B: Use a Virtual Machine (Good)
```bash
# Install VirtualBox or VMware, then:
# Download Ubuntu Server ISO
# Create a VM with: 2 CPU cores, 4 GB RAM, 25 GB disk
# Install and follow along
```

#### Option C: Use WSL on Windows (Quick Start)
```powershell
# Open PowerShell as Administrator
wsl --install
wsl --set-default-version 2
wsl --install -d Ubuntu-24.04
```

> 💡 **Recommendation:** Use Option A or B. WSL is convenient but will not teach you systemd, boot processes, or real server management.

---

## 📖 How to Read Each Part

Every part follows this exact structure:

```
┌─────────────────────────────────────────────────────────┐
│  # TITLE                                                │
│  ## Part N — Subtitle                                   │
│                                                         │
│  ## 🎯 What You Will Achieve                            │
│  (Explicit goals — tick them off as you go)             │
│                                                         │
│  ## 🔍 Section 1: Concept                               │
│  (Theory + real examples + diagrams)                    │
│                                                         │
│  ## 🔍 Section N: ...                                   │
│  (More concepts, building depth)                        │
│                                                         │
│  ## 💻 PRACTICE SECTION — N Hands-On Exercises          │
│  (Type every command. No exceptions.)                   │
│                                                         │
│  ## 🧠 Deep Understanding                               │
│  (How it really works under the hood)                   │
│                                                         │
│  ## 📋 Summary — Complete Command Reference             │
│  (Cheat sheet for this part)                            │
│                                                         │
│  ## 🚀 What's Coming in Part N+1                        │
│  (Preview of next topic)                                │
│                                                         │
│  ## 📝 Self-Test                                        │
│  (If you can't answer 80%, review before moving)        │
└─────────────────────────────────────────────────────────┘
```

### Symbols You Will See

| Symbol | Meaning |
|--------|---------|
| `💡` | Pro tip — make this a habit |
| `🔍` | Reverse engineering insight — understand why |
| `⚠️` | Warning — do not skip this |
| `🚨` | Critical danger — read twice before acting |
| `🛠️` | Hands-on practice — you must type this |
| `🧠` | Deep dive — how it works internally |
| `✅` | Practice exercise — do it before continuing |
| `📝` | Self-test question |

---

## ⏱️ Suggested Pace

| Pace | Time Per Part | Completion (60 parts) |
|------|--------------|----------------------|
| **Intensive** | 2-3 days | 4-6 months |
| **Balanced** | 4-5 days | 8-12 months |
| **Relaxed** | 1 week | 12-15 months |

> 💡 Sysadmin is not a sprint. It is a skill built over years. Focus on **understanding**, not speed. A part you truly understand is worth 10 parts you rushed through.

---

## 🧰 The SysAdmin Mindset — Start Building It Now

### 1. Assume Nothing, Verify Everything
```bash
# Beginner thinks:
"The system is fine."

# SysAdmin thinks:
"Let me check:"
systemctl status
df -h
free -h
journalctl -p err -b
```

### 2. Read Error Messages Completely
The error message tells you exactly what is wrong. Beginners stop reading when they see "ERROR". SysAdmins read the next 20 lines.

### 3. Automate Repetitive Work
If you have done something twice, write a script. If you have done it three times, turn it into a systemd service.

### 4. Document Everything
```bash
# Before you change a config file:
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak.$(date +%Y%m%d)

# After you fix something:
echo "2024-01-15: Fixed X by doing Y" >> ~/sysadmin_notes.md
```

### 5. Learn to Learn
The distro you use today may be obsolete in 5 years. The commands change. The tools change. But the **concepts** — processes, files, users, permissions, networking, storage — those never change. Learn the concepts.

---

## 📚 The 3 Books Every SysAdmin Should Read (Alongside This Course)

| Book | Why |
|------|-----|
| **The Linux Command Line** by William Shotts | Free online — best terminal reference |
| **Linux Administration Handbook** by Nemeth et al. | The classic — used by real sysadmins |
| **The Phoenix Project** by Gene Kim | Not technical — teaches why sysadmins matter |

---

## 🎓 Internship Program — Real-World Projects

In addition to the course modules, this repository includes a **24-week internship program** with levels mapped to the course progression. Each level produces portfolio-ready deliverables:

| Level | Weeks | Course Parts | Focus |
|-------|-------|-------------|-------|
| **Level 1** — Junior Linux Intern | 1-6 | Parts 1-10 | Onboarding, backups, disk alerting |
| **Level 2** — Systems Intern | 7-12 | Parts 11-25 | Service health, log servers, SSH hardening |
| **Level 3** — Infrastructure Intern | 13-18 | Parts 26-40 | Storage provisioning, health reports, Docker |
| **Level 4** — DevOps Intern | 19-24 | Parts 41-60 | Terraform, CI/CD, Kubernetes, SRE |

→ See [internships/](../internships/) directory for full details.

---

## 🏆 The Goal: What a Linux SysAdmin Actually Does

A Linux System Administrator is responsible for:

```
┌─────────────────────────────────────────────────────────┐
│                    DAY-TO-DAY WORK                       │
├─────────────────────────────────────────────────────────┤
│ 🔧 Install & configure servers                          │
│ 🔧 Monitor system health & performance                  │
│ 🔧 Manage user accounts & access                        │
│ 🔧 Apply security updates & patches                     │
│ 🔧 Back up data & plan disaster recovery                │
│ 🔧 Troubleshoot problems (hardware, software, network)  │
│ 🔧 Automate repetitive tasks with scripts               │
│ 🔧 Deploy applications & manage services                │
│ 🔧 Document systems and procedures                      │
│ 🔧 Respond to incidents & outages                       │
└─────────────────────────────────────────────────────────┘
```

### The Career Path

```
Junior SysAdmin (0-2 years)
  └─ Manage single servers, follow runbooks, handle tickets
      └─ Mid-Level SysAdmin (2-5 years)
          └─ Design infrastructure, automate workflows, mentor juniors
              └─ Senior SysAdmin (5+ years)
                  └─ Architecture, strategy, incident command
                      └─ DevOps / SRE / Platform Engineering
                          └─ Or: Infrastructure Manager
```

---

## 📋 Master Topic Index — All 60+ Parts

### Foundation (Parts 1-10) — 🟢 Phase 1: Basic

| Part | Title | Level |
|------|-------|-------|
| 0 | **The Master Plan** ← you are here | — |
| 1 | What Is Linux & How It Really Works | Basic |
| 2 | Mastering the Terminal — Navigation, Files & Directories | Basic |
| 3 | Users, Groups, and Permissions — Who Can Do What | Basic |
| 4 | Text Editors — Vim, Nano, and Why They Matter | Basic |
| 5 | Pipes, Redirection, and Streams — The Power of Unix | Basic |
| 6 | Shell Scripting — Automate Everything | Basic |
| 7 | Finding Things — grep, find, locate, and Beyond | Basic |
| 8 | Archiving and Compression — tar, gzip, zip | Basic |
| 9 | Process Management — ps, top, kill, and Signals | Basic |
| 10 | The Linux Boot Process — From Power On to Login | Basic |

### Essential Operations (Parts 11-25) — 🟡 Phase 2: Intermediary

| Part | Title | Level |
|------|-------|-------|
| 11 | Package Management — apt, dnf, yum, snap | Intermediary |
| 12 | Systemd and Services — Managing the Modern Linux | Intermediary |
| 13 | Scheduling Tasks — cron, at, systemd timers | Intermediary |
| 14 | Logging and Journald — Reading System Logs | Intermediary |
| 15 | SSH and Remote Access — Secure Connections | Intermediary |
| 16 | Firewalls — iptables, firewalld, nftables | Intermediary |
| 17 | SELinux and AppArmor — Mandatory Access Control | Intermediary |
| 18 | Environment Variables and Shell Configuration | Intermediary |
| 19 | Software Repositories and PPAs | Intermediary |
| 20 | System Updates and Patch Management | Intermediary |
| 21 | Time Synchronization — NTP and Chrony | Intermediary |
| 22 | Printers and CUPS | Intermediary |
| 23 | Virtual Terminals and Console Management | Intermediary |
| 24 | Kernel Modules and Device Drivers | Intermediary |
| 25 | System Rescue and Recovery | Intermediary |

### Storage and Filesystems (Parts 26-35) — 🟡 Phase 2: Intermediary

| Part | Title | Level |
|------|-------|-------|
| 26 | Disk Partitioning — fdisk, gdisk, parted | Intermediary |
| 27 | Filesystems — ext4, XFS, Btrfs, ZFS | Intermediary |
| 28 | Mounting and /etc/fstab | Intermediary |
| 29 | LVM — Logical Volume Manager | Intermediary |
| 30 | RAID — Redundant Arrays of Independent Disks | Intermediary |
| 31 | Disk Quotas — Limiting User Storage | Intermediary |
| 32 | Network Filesystems — NFS, Samba/CIFS | Intermediary |
| 33 | Backup Strategies — rsync, tar, dump, Borg | Intermediary |
| 34 | Encryption — LUKS and Encrypted Partitions | Intermediary |
| 35 | Disk Health Monitoring — SMART, badblocks | Intermediary |

### Networking (Parts 36-45) — 🔴 Phase 3: Advanced

| Part | Title | Level |
|------|-------|-------|
| 36 | Networking Fundamentals — TCP/IP, Subnetting | Advanced |
| 37 | Network Configuration — ip, nmcli, netplan | Advanced |
| 38 | DNS and Name Resolution — bind, systemd-resolved | Advanced |
| 39 | DHCP — Dynamic Host Configuration Protocol | Advanced |
| 40 | SSH Server Hardening and Tunneling | Advanced |
| 41 | Network Bonding and Teaming | Advanced |
| 42 | VPN — WireGuard, OpenVPN | Advanced |
| 43 | Packet Analysis — tcpdump, Wireshark | Advanced |
| 44 | Load Balancing — HAProxy, Nginx | Advanced |
| 45 | Network Troubleshooting — ping, traceroute, mtr, ss | Advanced |

### Servers and Applications (Parts 46-55) — 🔴 Phase 3: Advanced

| Part | Title | Level |
|------|-------|-------|
| 46 | Web Servers — Nginx and Apache | Advanced |
| 47 | Databases — MySQL, MariaDB, PostgreSQL | Advanced |
| 48 | Containers — Docker and Podman | Advanced |
| 49 | Container Orchestration — Docker Compose, Kubernetes Basics | Advanced |
| 50 | Monitoring — Prometheus, Grafana, Nagios | Advanced |
| 51 | CI/CD Basics — GitHub Actions, Jenkins | Advanced |
| 52 | Git — Version Control for SysAdmins | Advanced |
| 53 | Configuration Management — Ansible | Advanced |
| 54 | Infrastructure as Code — Terraform Basics | Advanced |
| 55 | Mail Servers — Postfix, Dovecot | Advanced |

### Advanced Topics (Parts 56+) — 🔴 Phase 3: Advanced

| Part | Title | Level |
|------|-------|-------|
| 56 | Kernel Tuning and Compilation | Advanced |
| 57 | Performance Analysis and Benchmarking | Advanced |
| 58 | Advanced Security — Auditing, Hardening, CIS Benchmarks | Advanced |
| 59 | High Availability and Clustering | Advanced |
| 60 | Disaster Recovery Planning | Advanced |
| 61 | Cloud Infrastructure — AWS, Azure, GCP Basics | Advanced |
| 62 | Interview Preparation and Certification (LPIC, RHCSA) | Advanced |
| 63+ | Future Topics — Community Requests | Advanced |

---

## ✅ Before You Start Part 1

Complete these setup steps now:

```bash
# 1. Verify Linux is installed
uname -a

# 2. Check your distribution
cat /etc/os-release

# 3. Check your user account
whoami
id

# 4. Check available disk space
df -h

# 5. Check available memory
free -h

# 6. Create a course directory to work in
mkdir -p ~/linux-course
cd ~/linux-course

# 7. Install essential tools
# Debian/Ubuntu:
sudo apt update && sudo apt install -y curl wget git vim tree htop

# Fedora/RHEL:
# sudo dnf install -y curl wget git vim tree htop
```

If all commands above ran without errors, you are **ready for Part 1**.

---

## 🧠 Final Words Before You Start

This course is 60+ parts. That sounds like a lot. But every single part was chosen because real sysadmins use that knowledge every day.

Nothing here is academic theory. Every command, every concept, every practice exercise exists because at some point, a sysadmin needed it to solve a real problem.

**Your job is not to memorize. Your job is to understand.**

When you understand how Linux works, you can work with any Linux distribution, any version, any environment — because the fundamentals never change.

Now close this file. Open your terminal. And begin Part 1.

---

*Linux SysAdmin Course | Part 0 of ∞ | The Master Plan*
*Next → Part 1: What Is Linux & How It Really Works*

[Next →](part1.md)
