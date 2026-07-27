# Collection of Absolutely All Concepts — Linux System Administration

> A comprehensive, hierarchical catalog of every concept a Linux system administrator must know — from beginner foundations to deep kernel internals and modern DevOps. This document serves as the master reference for the entire course.

---

## Table of Contents

1. [Linux Foundations — Parts 1-9](#level-1-linux-foundations)
2. [System Administration — Parts 10-25](#level-2-system-administration)
3. [Advanced Administration — Parts 26-36](#level-3-advanced-administration)
4. [Enterprise Services — Parts 37-49](#level-4-enterprise-services)
5. [Cloud & Modern DevOps — Parts 50-60](#level-5-cloud--modern-devops)
6. [Deep Internals — Parts 61-66](#level-6-deep-internals)
7. [Universal Concepts (Cross-Cutting)](#universal-concepts)

---

# Level 1: Linux Foundations

## 1.1 What Is Linux [Part 1]

- **Kernel vs Operating System** — The kernel is the core; the OS = kernel + userland tools + init system + libraries
- **Linus Torvalds** — Creator of Linux (1991), licensed under GPLv2
- **Open Source Philosophy** — Free software, community development, copyleft licensing
- **Linux Distributions** — Ubuntu, Debian, Fedora, Rocky Linux, RHEL, Arch, SUSE, Alpine, Gentoo
- **Debian-based vs RHEL-based vs Arch-based** — Package managers, release cycles, target audiences
- **Linux vs Windows vs macOS** — Architecture differences, file systems, security models, use cases
- **POSIX Compliance** — Portable Operating System Interface standard for Unix-like systems
- **GNU/Linux** — The relationship between GNU tools and the Linux kernel
- **Linux on Everything** — Servers (96.4% of top 1M web servers), cloud, embedded, Android, IoT, supercomputers (100% of top 500), mainframes, desktops

## 1.2 Terminal and Shell [Part 2]

- **Terminal Emulator** — GUI program that provides a terminal session (gnome-terminal, konsole, xterm, alacritty, kitty)
- **Shell** — Command interpreter between user and kernel (bash, zsh, fish, dash, ksh)
- **Command Line Interface (CLI)** — Text-based interaction with the system
- **Bash (Bourne Again Shell)** — Default shell on most Linux distributions
- **Shell Prompt** — `user@hostname:directory$` structure
- **Command Syntax** — `command [options] [arguments]`
- **Command History** — Up/Down arrows, `history` command, `!n` (run nth command), `!!` (last command)
- **Tab Completion** — Auto-completing commands, filenames, options
- **Keyboard Shortcuts** — Ctrl+C (interrupt), Ctrl+Z (suspend), Ctrl+D (exit), Ctrl+R (search history), Ctrl+A/E (beginning/end of line), Ctrl+U/K (kill before/after cursor)
- **Working Directory** — `pwd` (print working directory)
- **Path Navigation** — `cd`, `cd ~`, `cd -`, `cd ..`, `cd /path`
- **Relative vs Absolute Paths** — `./file` vs `/home/user/file`
- **Tilde (~)** — Shorthand for home directory
- **DOT (.) files** — Hidden files/directories, `ls -a` to view
- **Shebang (#!)** — First line of script specifying interpreter (`#!/bin/bash`)

## 1.3 File System Hierarchy [Part 2]

- **FHS (Filesystem Hierarchy Standard)** — Standard directory layout for Linux
- **Root Directory (/)** — Top of the filesystem tree
- **/home** — User home directories
- **/etc** — System-wide configuration files
- **/var** — Variable data: logs, caches, spool, databases
- **/tmp** — Temporary files (cleared on reboot)
- **/usr** — User programs, libraries, documentation (secondary hierarchy)
- **/usr/bin** — User commands
- **/usr/lib** — Libraries
- **/usr/local** — Locally installed software
- **/opt** — Third-party software packages
- **/bin** — Essential user command binaries
- **/sbin** — System binaries (root/admin use)
- **/lib** — Shared libraries for /bin and /sbin
- **/dev** — Device files (disk, terminal, null, random)
- **/proc** — Virtual filesystem for process/kernel information
- **/sys** — Virtual filesystem for device/driver/kernel info
- **/boot** — Boot loader files, kernel images, initramfs
- **/mnt** — Temporary mount points
- **/media** — Mount points for removable media
- **/run** — Runtime data (PIDs, sockets)
- **/srv** — Data for services (web, FTP)
- **/lost+found** — Recovered filesystem fragments (ext4)
- **/etc/os-release** — Distribution identification

## 1.4 File Operations [Part 2]

- **ls** — List files (ls -la, ls -lh, ls -R, ls -ltr)
- **cp** — Copy files/directories (cp -r, cp -p, cp -a)
- **mv** — Move/rename files
- **rm** — Remove files (rm -rf — dangerous!)
- **mkdir** — Create directories (mkdir -p for nested)
- **rmdir** — Remove empty directories
- **touch** — Create empty file or update timestamp
- **cat** — Display file contents
- **less / more** — Paginated file viewer
- **head / tail** — First/last lines of file (tail -f for live logs)
- **ln** — Hard links (ln) and symbolic links (ln -s)
- **File Extensions** — Not mandatory in Linux but conventional (.conf, .sh, .txt, .log)
- **File Types** — Regular file (-), directory (d), link (l), character device (c), block device (b), socket (s), pipe (p)
- **stat** — Detailed file metadata (inode, permissions, timestamps)
- **file** — Determine file type by content (magic bytes)
- **du** — Disk usage per file/directory (du -sh)
- **df** — Disk free space per filesystem (df -h)
- **find** — Find files by name, size, time, type, permissions
- **locate / updatedb** — Fast filename database search
- **which / whereis** — Find command location and man pages
- **Tree** — Visual directory structure

## 1.5 Users, Groups, and Permissions [Part 3]

- **User Types** — root (UID 0), system users (1-999), regular users (1000+)
- **/etc/passwd** — User account information (username:x:UID:GID:comment:home:shell)
- **/etc/shadow** — Encrypted passwords and password policies
- **/etc/group** — Group membership information
- **/etc/gshadow** — Group shadow file (secure group info)
- **useradd / adduser** — Create users (useradd -m -s /bin/bash)
- **usermod** — Modify user accounts (-aG for append group)
- **userdel** — Delete users (-r to remove home directory)
- **passwd** — Set/change passwords
- **id** — Show user UID, GID, groups
- **whoami** — Current username
- **groups** — Groups a user belongs to
- **groupadd / groupmod / groupdel** — Group management
- **su** — Switch user (su - username)
- **sudo** — Execute as superuser
- **/etc/sudoers** — Sudo configuration (visudo to edit safely)
- **sudoers.d** — Drop-in sudo configuration directory
- **chmod** — Change file permissions
  - Symbolic mode: `chmod u+x file`, `chmod g+w file`, `chmod o-r file`
  - Numeric mode: `chmod 755 file` (rwxr-xr-x)
- **chown** — Change file owner and group (chown user:group file)
- **chgrp** — Change group ownership
- **Permission Bits** — Read (4), Write (2), Execute (1); User/Group/Other
- **Special Permissions** — SUID (4), SGID (2), Sticky Bit (1)
  - SUID: Run as file owner (e.g., /usr/bin/passwd)
  - SGID: Inherit group or run as group
  - Sticky Bit: Only owner can delete (e.g., /tmp)
- **umask** — Default permission mask (0022 typical)
- **Access Control Lists (ACLs)** — Fine-grained permissions (getfacl, setfacl)

## 1.6 Text Processing [Part 4]

- **Vim** — Modal editor (Normal, Insert, Visual modes); vi improved
  - Navigation: h/j/k/l, w/b/e, 0/$, gg/G
  - Editing: i/a/o, x/dd/yy/p/u, :w/:q/:wq/:q!
  - Search: /pattern, n/N
  - Visual mode: v/V Ctrl+v
  - Split windows: :sp/:vs, Ctrl+w navigation
  - Macros: q{letter}, @{letter}
- **Nano** — Simple, intuitive editor (Ctrl+O save, Ctrl+X exit)
- **Emacs** — Extensible editor (Ctrl+x Ctrl+s save, Ctrl+x Ctrl+c exit)
- **sed** — Stream editor (find/replace, delete, insert)
  - `sed 's/old/new/g' file`
  - `sed -i` (in-place editing)
  - `sed -n '10,20p' file` (print lines 10-20)
- **awk** — Pattern scanning and processing language
  - `awk '{print $1, $3}' file` (print fields)
  - `awk -F: '{print $1}' /etc/passwd` (custom delimiter)
  - `awk '/pattern/ {action}' file`
- **grep** — Global Regular Expression Print
  - `grep -r` (recursive), `grep -i` (case insensitive), `grep -v` (invert)
  - `grep -E` (extended regex), `grep -P` (Perl regex)
  - `grep -c` (count), `grep -l` (files with matches), `grep -n` (line numbers)
- **Regular Expressions** — Basic (BRE) vs Extended (ERE) vs Perl (PCRE)
  - Anchors: ^, $
  - Quantifiers: *, +, ?, {n}, {n,m}
  - Character classes: [0-9], [a-z], \d, \w, \s
  - Groups: (group), \1 backreference
- **cut** — Cut fields/characters from lines
- **sort** — Sort lines
- **uniq** - Report unique lines (use with sort)
- **wc** — Word count (lines, words, characters)
- **tr** — Translate/delete characters
- **diff / vimdiff** — Compare files
- **tee** — Read from stdin and write to file AND stdout
- **xargs** — Build command lines from stdin
- **Column** — Format columns of text

## 1.7 Pipes, Redirection, and Streams [Part 5]

- **Standard Streams** — stdin (0), stdout (1), stderr (2)
- **Output Redirection** — `>` (overwrite), `>>` (append)
- **Input Redirection** — `< file`
- **Error Redirection** — `2>`, `2>>`, `2>&1`
- **Null Output** — `/dev/null` (discard output)
- **Pipe (|)** — Connect stdout of one command to stdin of another
- **Process Substitution** — `<()` and `>()`
- **Here Documents** — `<<EOF ... EOF`
- **Here Strings** — `<<< "string"`
- **File Descriptors** — 0 (stdin), 1 (stdout), 2 (stderr), 3+ (custom)
- **Redirection Order** — `2>&1` vs `&>`

## 1.8 Shell Scripting Basics [Part 6]

- **Variables** — `VAR=value` (no spaces), `$VAR` or `${VAR}` to access
- **Environment Variables** — `export VAR=value` (inherited by child processes)
- **Local Variables** — Only in current shell
- **Special Variables** — $0 (script name), $1-$9 (arguments), $# (arg count), $? (exit status), $$ (PID), $@/$* (all args)
- **Quoting** — Single quotes (literal), double quotes (variable expansion), backslash (escape)
- **Command Substitution** — `$(command)` or `` `command` ``
- **Arithmetic** — `$((expression))`, `let`, `expr`
- **Conditionals** — if/elif/else/fi, test/[]/[[]]
  - File tests: -f (regular file), -d (directory), -r (readable), -w (writable), -x (executable), -e (exists), -s (non-empty)
  - String tests: =, !=, -z (empty), -n (non-empty)
  - Numeric tests: -eq, -ne, -lt, -le, -gt, -ge
- **Case Statements** — case/esac pattern matching
- **Loops** — for, while, until
  - `for i in list; do ...; done`
  - `for ((i=0; i<10; i++)); do ...; done`
  - `while condition; do ...; done`
  - `until condition; do ...; done`
- **Functions** — `funcname() { ... }` or `function funcname { ... }`
- **Exit Codes** — 0 (success), non-zero (failure)
- **set -e** — Exit on error
- **set -u** — Exit on undefined variable
- **set -x** — Debug mode (print commands)
- **trap** — Handle signals (trap 'cleanup' EXIT INT TERM)
- **Arrays** — `arr=(a b c)`, `${arr[0]}`, `${arr[@]}`
- **String Manipulation** — ${#var} (length), ${var:offset:length} (substring), ${var/old/new} (replace)

## 1.9 Archiving and Compression [Part 8]

- **tar** — Tape archive
  - `tar -czf archive.tar.gz dir/` (create gzip)
  - `tar -cjf archive.tar.bz2 dir/` (create bzip2)
  - `tar -xzf archive.tar.gz` (extract gzip)
  - `tar -tf archive.tar.gz` (list contents)
- **gzip / gunzip** — Single file compression (.gz)
- **bzip2 / bunzip2** — Higher compression, slower (.bz2)
- **xz / unxz** — Best compression ratio (.xz)
- **zip / unzip** — Cross-platform archiving (.zip)
- **zcat / zless** — View gzipped files without extracting
- **Compression Tradeoffs** — Speed vs ratio; gzip (fast), bzip2 (medium), xz (slow, best)

## 1.10 Process Management [Part 9]

- **Process** — Running instance of a program
- **Process States** — Running (R), Sleeping (S), Stopped (T), Zombie (Z), Disk Sleep (D)
- **PID (Process ID)** — Unique numeric identifier
- **PPID (Parent PID)** — Parent process identifier
- **ps** — Snapshot of processes (ps aux, ps -ef, ps -eo pid,ppid,cmd)
- **top** — Real-time process viewer (interactive: M=sort by mem, P=sort by cpu, k=kill, r=renice)
- **htop** — Enhanced top (tree view, mouse support, color)
- **pgrep / pkill** — Find/kill processes by name
- **kill** — Send signal to process (kill -9 SIGKILL, kill -15 SIGTERM, kill -1 SIGHUP)
- **killall** — Kill all processes by name
- **Signals** — SIGTERM (15, graceful), SIGKILL (9, force), SIGHUP (1, reload), SIGSTOP (19, pause), SIGCONT (18, resume), SIGUSR1/2 (user-defined)
- **nice** — Start process with modified priority (-20 to 19, lower = higher priority)
- **renice** — Change priority of running process
- **Background / Foreground** — & (background), jobs, fg, bg, Ctrl+Z
- **nohup** — Run command immune to hangups
- **Process Priority** — nice value, real-time priorities
- **zombie Processes** — Terminated but not reaped by parent
- **orphan Processes** — Parent died, adopted by init/systemd
- **/proc/[pid]/** — Process virtual filesystem
- **Environment** — Process inherits environment from parent
- **fork** — System call to create child process
- **exec** — System call to replace process image
- **wait** — Wait for child process to complete

## 1.11 Finding Things [Part 7]

- **find** — Powerful file search
  - `find /path -name "*.conf"`
  - `find / -type f -size +100M`
  - `find . -mtime -7` (modified in last 7 days)
  - `find . -perm 777` (exact permissions)
  - `find . -exec command {} \;` (execute on results)
  - `find . -delete` (delete matches)
- **locate** — Fast search using pre-built database (updatedb, locate -i)
- **which** — Find command in PATH
- **whereis** — Find binary, source, man page
- **type** — Show command type (builtin, alias, file)
- **apropos / man -k** — Search man pages by keyword
- **fd** — Modern find alternative (faster, more intuitive)
- **ripgrep (rg)** — Modern grep alternative (faster)

---

# Level 2: System Administration

## 2.1 Linux Boot Process [Part 10]

- **Power On → BIOS/UEFI → Bootloader → Kernel → initramfs → Init System → Login**
- **BIOS (Legacy)** — Reads MBR (446 bytes), limited to 2TB disks, 4 primary partitions
- **UEFI (Modern)** — Reads EFI System Partition (FAT32), supports GPT (9.4 ZB), Secure Boot, NVRAM boot entries
- **POST (Power-On Self-Test)** — Hardware initialization and diagnostics
- **MBR (Master Boot Record)** — 512 bytes: 446 boot code + 64 partition table + 2 signature
- **GPT (GUID Partition Table)** — Modern partition scheme, supports large disks, redundant headers
- **EFI System Partition (ESP)** — FAT32 partition mounted at /boot/efi
- **GRUB 2 (Grand Unified Bootloader)** — Loads kernel and initramfs
  - Configuration: /boot/grub/grub.cfg (generated from /etc/default/grub + /etc/grub.d/)
  - `grub2-mkconfig` / `update-grub` — Regenerate config
  - GRUB rescue mode — Recovery from broken boot
  - Kernel parameters — `quiet`, `rhgb`, `single`/`init=/bin/bash`
- **systemd-boot** — Lightweight UEFI boot manager
- **Kernel Image** — vmlinuz (compressed), vmlinux (uncompressed)
- **initramfs (Initial RAM Filesystem)** — Temporary root filesystem loaded into memory
  - Solves chicken-and-egg problem (need drivers to mount root)
  - Contains essential drivers (storage, filesystem)
  - `dracut` / `mkinitramfs` — Rebuild initramfs
  - `switch_root` — Transition from initramfs to real root
- **Kernel Panic** — Fatal kernel error (analogous to BSOD)
- **Single-User / Rescue Mode** — Minimal boot for maintenance
- **systemd Targets (formerly runlevels)**
  - poweroff.target (0), rescue.target (1), multi-user.target (3), graphical.target (5), reboot.target (6)
  - `systemctl get-default` / `systemctl set-default`
- **Boot Stages Summary**:
  1. Firmware (BIOS/UEFI) → POST, hardware init, find boot device
  2. Bootloader (GRUB) → Load kernel + initramfs into memory
  3. Kernel → Initialize hardware, mount initramfs
  4. Init System (systemd) → Start services, mount filesystems, configure networking
  5. Login (getty/display manager) → Present login prompt
- **Boot Diagnostics** — `dmesg` (kernel messages), `journalctl -b` (boot logs), `systemd-analyze` (boot time)

## 2.2 Package Management [Part 11]

- **dpkg (Debian Package)** — Low-level package installer (.deb)
- **apt (Advanced Package Tool)** — High-level package manager for Debian/Ubuntu
  - `apt update`, `apt install`, `apt remove`, `apt upgrade`, `apt autoremove`
  - `apt-cache search`, `apt-cache show`
- **rpm (Red Hat Package Manager)** — Low-level package installer (.rpm)
- **dnf (Dandified YUM)** — Modern package manager for Fedora/RHEL/CentOS
  - `dnf install`, `dnf remove`, `dnf update`, `dnf search`, `dnf info`
  - `dnf module` — Module streams (RHEL 8+)
- **yum** — Legacy package manager (replaced by dnf)
- **zypper** — Package manager for SUSE/openSUSE
- **pacman** — Package manager for Arch Linux
- **snap** — Universal Linux packages (Ubuntu/Canonical)
- **flatpak** — Cross-distribution application packaging
- **AppImage** — Portable Linux applications
- **Package Repositories** — Main, universe, multiverse, restricted; baseos, appstream
- **Package Signing** — GPG keys for verifying package authenticity
- **Dependency Resolution** — Automatic handling of package dependencies
- **Package Downgrading** — `apt install package=version` or `dnf downgrade`
- **dpkg-reconfigure** — Reconfigure already-installed packages
- **dpkg -l** — List installed packages
- **rpm -qa** — Query all installed RPM packages
- **Repo Files** — /etc/apt/sources.list or /etc/yum.repos.d/
- **PPAs (Personal Package Archives)** — Third-party repositories (Ubuntu)
- **Third-Party Repositories** — Adding external repos (EPEL, RPM Fusion)

## 2.3 Systemd and Services [Part 12]

- **systemd** — Modern init system and service manager (PID 1)
- **systemctl** — Control systemd services and system state
  - `systemctl start/stop/restart/reload service`
  - `systemctl enable/disable service` (boot-time start)
  - `systemctl status service`
  - `systemctl list-units`, `systemctl list-unit-files`
  - `systemctl is-active service`, `systemctl is-enabled service`
- **Unit Files** — Configuration for systemd services
  - [Unit] — Description, After, Before, Requires, Wants
  - [Service] — Type (simple, forking, oneshot), ExecStart, ExecStop, Restart, User, WorkingDirectory
  - [Install] — WantedBy (target)
  - Locations: /etc/systemd/system/ (admin), /usr/lib/systemd/system/ (package), /run/systemd/system/ (runtime)
- **Service Types** — Type=simple, Type=forking, Type=oneshot, Type=notify, Type=dbus
- **systemd Targets** — Group of units (multi-user.target, graphical.target, network-online.target)
- **systemd-journald** — Systemd logging daemon
  - `journalctl -u service` (service logs)
  - `journalctl -f` (follow logs)
  - `journalctl -b` (current boot)
  - `journalctl -p err` (priority filter)
  - `journalctl --since "2024-01-01"`
- **systemd-timers** — Cron replacement
  - [Timer] section: OnCalendar, OnBootSec, Persistent=true
- **Socket Activation** — Start services on demand via socket
- **D-Bus Activation** — Start services when D-Bus name is accessed
- **systemd-analyze** — Boot time analysis
  - `systemd-analyze blame` — Show service startup times
  - `systemd-analyze critical-chain` — Show dependency chain
- **systemd-resolved** — DNS stub resolver
- **systemd-networkd** — Network management daemon
- **SysVinit Compatibility** — update-rc.d, chkconfig, systemctl legacy links

## 2.4 Scheduling Tasks [Part 13]

- **cron** — Time-based job scheduler
  - `crontab -e` — Edit cron jobs
  - `crontab -l` — List cron jobs
  - Cron syntax: `minute hour day-of-month month day-of-week command`
  - Special strings: @reboot, @daily, @weekly, @monthly, @yearly
  - System crontabs: /etc/crontab, /etc/cron.d/, /etc/cron.daily/
  - Cron permissions: /etc/cron.allow, /etc/cron.deny
  - LOG_FILE: Standard output goes to /var/mail or syslog
- **at** — One-time task scheduler
  - `echo "command" | at midnight`
  - `atq` — List pending jobs
  - `atrm` — Remove job
- **systemd timers** — Modern replacement for cron
  - OnCalendar (calendar events), OnBootSec, OnUnitActiveSec
  - Persistent=true (run missed jobs after boot)
- **anacron** — Run missed cron jobs on systems not running 24/7
  - /etc/anacrontab — delay, period, job
- **batch** — Execute commands when system load drops below threshold

## 2.5 Logging and Monitoring [Part 14]

- **Syslog** — Traditional Unix logging system
  - /var/log/syslog (Debian/Ubuntu) or /var/log/messages (RHEL/CentOS)
  - /var/log/auth.log — Authentication logs
  - /var/log/kern.log — Kernel logs
  - /var/log/dmesg — Boot messages
  - /var/log/cron.log — Cron job logs
  - /var/log/secure — Security logs (RHEL)
  - /var/log/maillog — Mail server logs
- **rsyslog** — Reliable syslog implementation
  - Configuration: /etc/rsyslog.conf
  - Facilities: auth, cron, daemon, kern, mail, user, local0-7
  - Priorities: emerg, alert, crit, err, warning, notice, info, debug
  - Remote logging: @@hostname (TCP), @hostname (UDP)
- **journald** — Systemd's logging system
  - Persistent storage: /var/log/journal/
  - `journalctl` — Query journal
  - Log levels: emerg(0) through debug(7)
  - Log rotation: Systemd-managed via /etc/systemd/journald.conf
  - Forward to syslog: ForwardToSyslog=yes
- **logrotate** — Log rotation and management
  - Configuration: /etc/logrotate.conf, /etc/logrotate.d/
  - Directives: daily/weekly/monthly, rotate N, compress, delaycompress, missingok, notifempty
  - postrotate/endscript — Commands to run after rotation
- **dmesg** — Kernel ring buffer messages
- **/var/log/audit/audit.log** — SELinux audit logs
- **Centralized Logging** — ELK Stack (Elasticsearch, Logstash, Kibana), Graylog, Fluentd, Loki
- **Log Severity Levels** — 0 (emerg) to 7 (debug)

## 2.6 SSH and Remote Access [Part 15]

- **SSH (Secure Shell)** — Encrypted remote access protocol
  - Port 22 (default)
  - `ssh user@host` — Connect to remote host
  - `ssh -p port user@host` — Custom port
- **OpenSSH** — Most common SSH implementation
  - Server: sshd (daemon), config: /etc/ssh/sshd_config
  - Client: ssh, config: /etc/ssh/ssh_config or ~/.ssh/config
- **Key-Based Authentication**
  - `ssh-keygen -t ed25519` — Generate key pair
  - `ssh-copy-id user@host` — Copy public key to server
  - Private key permissions: 600, Public key: 644
  - ~/.ssh/authorized_keys — Authorized public keys
- **SSH Agent** — `ssh-agent`, `ssh-add` — Cache keys in memory
- **SSH Tunneling / Port Forwarding**
  - Local: `ssh -L localport:host:port user@gateway`
  - Remote: `ssh -R remoteport:localhost:port user@host`
  - Dynamic (SOCKS proxy): `ssh -D port user@host`
- **SSH Config File** — ~/.ssh/config for host aliases
- **SCP (Secure Copy)** — `scp file user@host:/path`
- **rsync over SSH** — Efficient file synchronization
- **sftp** — Secure FTP over SSH
- **SSH Hardening** — Disable root login, use key-only auth, change port, use AllowUsers
- **sshd_config Options** — PermitRootLogin, PasswordAuthentication, PubkeyAuthentication, Port, AllowUsers, MaxAuthTries
- **fail2ban** — Ban IPs with too many failed login attempts
- **mosh (Mobile Shell)** — UDP-based SSH alternative for unstable connections
- **tmux / screen** — Terminal multiplexers for persistent sessions

## 2.7 Firewalls [Part 16]

- **iptables** — Legacy Linux firewall (netfilter framework)
  - Chains: INPUT, OUTPUT, FORWARD, PREROUTING, POSTROUTING
  - Tables: filter, nat, mangle, raw
  - `iptables -A INPUT -p tcp --dport 22 -j ACCEPT`
  - `iptables -A INPUT -j DROP`
  - Rules are processed top to bottom (first match wins)
- **nftables** — Replacement for iptables (simpler syntax, better performance)
  - `nft add rule inet filter input tcp dport 22 accept`
  - Tables, chains, rules — unified framework
- **firewalld** — Dynamic firewall daemon (RHEL/CentOS/Fedora)
  - Zones: public, internal, trusted, drop, dmz
  - `firewall-cmd --add-port=80/tcp --permanent`
  - `firewall-cmd --reload`
  - Rich rules for complex firewall logic
- **ufw (Uncomplicated Firewall)** — Simple firewall (Ubuntu/Debian)
  - `ufw allow 22/tcp`
  - `ufw enable / disable`
  - `ufw status verbose`
  - Application profiles: `ufw allow 'OpenSSH'`
- **iptables-nft** — iptables compatibility layer on nftables
- **Connection Tracking** — conntrack (stateful firewall)
  - States: NEW, ESTABLISHED, RELATED, INVALID
- **NAT (Network Address Translation)** — SNAT, DNAT, MASQUERADE
  - `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE`
- **Port Forwarding** — DNAT rules for incoming traffic
- **IP Forwarding** — `/proc/sys/net/ipv4/ip_forward`
- **Rate Limiting** — `-m limit --limit 10/min --limit-burst 20`
- **Logging Dropped Packets** — `-j LOG --log-prefix "DROP: "`

## 2.8 SELinux and AppArmor [Part 17]

- **MAC (Mandatory Access Control)** — Kernel-enforced security beyond DAC
- **DAC (Discretionary Access Control)** — Standard Unix permissions (owner/group/other)
- **SELinux (Security-Enhanced Linux)** — Label-based MAC (RHEL/Fedora/CentOS)
  - Modes: Enforcing, Permissive, Disabled
  - `getenforce` / `setenforce 0|1`
  - Contexts: user:role:type:level (e.g., httpd_sys_content_t)
  - `ls -Z` — View file contexts
  - `ps -eZ` — View process contexts
  - `chcon` — Change context (temporary)
  - `restorecon` — Restore default contexts
  - `semanage fcontext` — Permanent context rules
  - `semanage port` — Manage port labels
  - `audit2why` / `audit2allow` — Debug and generate policy
  - `setroubleshoot` — GUI troubleshooting
  - Booleans: `getsebool -a`, `setsebool`
- **AppArmor** — Path-based MAC (Ubuntu/Debian)
  - Modes: Enforce, Complain
  - `aa-status` — Show status
  - Profiles in /etc/apparmor.d/
  - `aa-enforce`, `aa-complain`, `aa-disable`
  - `aa-genprof` — Generate profiles
- **Linux Security Modules (LSM)** — Framework that enables SELinux, AppArmor, and others
- **Capabilities** — Fine-grained root privileges
  - CAP_NET_BIND_SERVICE, CAP_SYS_ADMIN, CAP_SYS_PTRACE, etc.
  - `setcap cap_net_bind_service=+ep /path/to/binary`
  - `getcap /path/to/binary`
- **Seccomp** — System call filtering
- **Kernel Hardening** — sysctl parameters for security

## 2.9 Environment Variables and Shell Configuration [Part 18]

- **Environment Variables** — System-wide or user-specific settings
  - PATH, HOME, USER, SHELL, LANG, LC_*, TERM, PS1, HOSTNAME
  - `env` / `printenv` — List all environment variables
  - `echo $VARIABLE` — Print variable value
  - `export VAR=value` — Set and export variable
- **Shell Configuration Files**
  - /etc/environment — System-wide
  - /etc/profile, /etc/profile.d/* — System-wide (login shells)
  - ~/.bash_profile, ~/.bash_login, ~/.profile — User login
  - ~/.bashrc — User interactive non-login shells
  - /etc/bash.bashrc — System-wide interactive shell
- **PS1** — Shell prompt customization
- **PATH** — Directories to search for commands
- **LD_LIBRARY_PATH** — Additional library search paths
- **Shell Initialization Order** — Login: /etc/profile → ~/.profile; Interactive: ~/.bashrc
- **Aliase** — `alias ll='ls -la'`
- **Prompt Variables** — \u (user), \h (hostname), \w (directory), \W (basename)
- **umask** — Default file permissions
- **locale** — Localization and internationalization settings
- **timedatectl** — Timezone and NTP configuration

## 2.10 Software Repositories [Part 19]

- **Official Repositories** — Distribution-provided package sources
- **Third-Party Repositories** — EPEL, RPM Fusion, PPAs, OBS
- **Repository Configuration**
  - Debian/Ubuntu: /etc/apt/sources.list, /etc/apt/sources.list.d/
  - RHEL/CentOS: /etc/yum.repos.d/*.repo
- **GPG Keys** — Package signing and verification
  - `apt-key` (deprecated), `/etc/apt/trusted.gpg.d/`
  - `rpm --import`
- **Repository Priorities** — Package version selection across repos
- **Mirror Servers** — Choosing geographically close mirrors

## 2.11 System Updates and Patch Management [Part 20]

- **Security Updates** — Patches for vulnerabilities (critical CVEs)
- **Kernel Live Patching** — Patch running kernel without reboot (kpatch, kGraft, livepatch)
  - Adoption up 31.5% in enterprise environments (2025)
- **Unattended Upgrades** — Automatic security patching
  - `unattended-upgrades` (Debian/Ubuntu)
  - `dnf-automatic` (RHEL/Fedora)
- **Reboot Required** — Kernel updates need reboot (or live patch)
- **Testing Patches** — Staging environments before production
- **Rollback** — Package downgrade, snapshot-based rollback
- **Release Upgrades** — Ubuntu do-release-upgrade, DNF system-upgrade
- **Changelog Review** — Review changes before applying

## 2.12 Time Synchronization [Part 21]

- **NTP (Network Time Protocol)** — Synchronize clocks over network
- **chrony** — Modern NTP implementation (replacement for ntpd)
  - `chronyc sources` — Show NTP sources
  - `/etc/chrony.conf` — Configuration
- **ntpd** — Traditional NTP daemon
- **systemd-timesyncd** — Lightweight SNTP client
- **timedatectl** — Check/set time, timezone, NTP status
  - `timedatectl set-timezone America/New_York`
  - `timedatectl set-ntp true`
- **Hardware Clock vs System Clock** — hwclock commands
- **Coordinated Universal Time (UTC)** — Standard time reference
- **Timezones** — /usr/share/zoneinfo/, /etc/localtime

## 2.13 Network Services [Part 22]

- **DHCP (Dynamic Host Configuration Protocol)** — Automatic IP assignment
- **DNS (Domain Name System)** — Name resolution
- **HTTP/HTTPS** — Web servers (Apache, Nginx)
- **SSH** — Secure remote access
- **NTP** — Time synchronization
- **FTP/SFTP** — File transfer
- **SMTP/IMAP/POP3** — Mail services
- **LDAP** — Directory services
- **SNMP** — Network management

## 2.14 Virtual Terminals and Console Management [Part 23]

- **Virtual Terminals (TTY)** — Ctrl+Alt+F1-F6 (typically 6 consoles)
- **tty** — Current terminal device
- **who** — Who is logged in
- **w** — Who is logged in and what they're doing
- **last / lastb** — Login history
- **mesg** — Allow/deny messages
- **write / wall** — Send messages to other users
- **Terminal Multiplexers** — tmux, screen (persistent sessions)
  - tmux: create session, attach/detach, windows, panes
  - screen: -S (create), -r (reattach), Ctrl+A shortcuts

## 2.15 Kernel Modules [Part 24]

- **Kernel Modules** — Loadable kernel code
- **lsmod** — List loaded modules
- **modinfo** — Module information
- **modprobe** — Load/unload modules with dependencies
- **insmod / rmmod** — Low-level module operations
- **/etc/modprobe.d/** — Module configuration
- **Blacklisting** — Preventing modules from loading
- **/proc/modules** — Currently loaded modules
- **DKMS** — Dynamic Kernel Module Support (auto-rebuild on kernel update)
- **depmod** — Generate module dependency list

## 2.16 System Rescue and Recovery [Part 25]

- **GRUB Rescue** — Fixing broken bootloaders
- **Single-User Mode** — Minimal boot for maintenance
- **Live USB/CD** — Rescue media for system recovery
- **fsck** — Filesystem check and repair
- **mount/remount** — Mount filesystems manually
- **Chroot** — Change root for recovery
- **initramfs Recovery** — Rebuild from rescue media
- **System Rollback** — Btrfs snapshots, LVM snapshots, Timeshift
- **Backup Restoration** — Restoring from backups
- **Emergency Mode** — systemd emergency.target (minimal services)
- **Recovery Partition** — Vendor-provided recovery options

---

# Level 3: Advanced Administration

## 3.1 Network Configuration [Part 26]

- **ip command** — Modern network configuration (replaces ifconfig, route)
  - `ip addr show` — Show IP addresses
  - `ip link show` — Show network interfaces
  - `ip route show` — Show routing table
  - `ip addr add 192.168.1.10/24 dev eth0`
  - `ip link set eth0 up/down`
  - `ip route add default via 192.168.1.1`
- **nmcli** — NetworkManager command-line
  - `nmcli con show`, `nmcli dev status`
  - `nmcli con add type ethernet ifname eth0`
- **nmtui** — Text-based NetworkManager UI
- **netplan** — Network configuration abstraction (Ubuntu 17.10+)
  - /etc/netplan/*.yaml — YAML configuration
  - `netplan apply`
- **/etc/network/interfaces** — Traditional Debian network config
- **/etc/sysconfig/network-scripts/** — RHEL/CentOS network scripts
- **DNS Configuration**
  - /etc/resolv.conf — DNS nameservers
  - /etc/hosts — Static hostname-to-IP mapping
  - /etc/nsswitch.conf — Name resolution order (files, dns, mdns4)
- **Network Interfaces** — eth0, ens*, enp*, wlp*, docker0, br-*, veth*
- **Bonding / Teaming** — Aggregate multiple NICs for redundancy/bandwidth
  - modes: active-backup, balance-rr, balance-xor, 802.3ad (LACP)
- **VLANs** — Virtual LANs (802.1Q tagging)
- **Bridging** — Virtual network bridges (for VMs, containers)
  - `brctl addbr br0`, `brctl addif br0 eth0`
  - ip bridge commands
- **MTU (Maximum Transmission Unit)** — Packet size limit
- **Jumbo Frames** — MTU > 1500 (for storage networks)

## 3.2 DNS and Name Resolution [Part 27]

- **DNS Hierarchy** — Root → TLD → Second-level → Subdomain
- **Types of DNS Records**
  - A — IPv4 address
  - AAAA — IPv6 address
  - CNAME — Canonical name (alias)
  - MX — Mail exchanger
  - NS — Name server
  - TXT — Text record (SPF, DKIM, verification)
  - SOA — Start of Authority
  - PTR — Reverse DNS
  - SRV — Service locator
  - CAA — Certificate Authority Authorization
- **BIND (Berkeley Internet Name Domain)** — Most common DNS server
  - named.conf, zone files, rndc
  - Forward zones, reverse zones
  - SOA record fields (serial, refresh, retry, expire, minimum TTL)
- **dnsmasq** — Lightweight DNS/DHCP server
- **Unbound** — Validating, recursive DNS resolver
- **Systemd-resolved** — Stub resolver (/etc/resolv.conf → 127.0.0.53)
- **dig** — DNS lookup tool
  - `dig example.com`, `dig @8.8.8.8 example.com`
  - `dig +short`, `dig +trace`
- **nslookup** — Simple DNS lookup
- **host** — Simple DNS lookup
- **/etc/nsswitch.conf** — Name resolution order
- **DNS Caching** — Local caching for performance
- **Split DNS** — Different responses based on source
- **DNSSEC** — DNS security extensions (cryptographic signing)
- **DNS-over-HTTPS (DoH) / DNS-over-TLS (DoT)** — Encrypted DNS

## 3.3 Network File System (NFS) [Part 28]

- **NFS (Network File System)** — Share directories over network
- **NFS Server**
  - `/etc/exports` — Share definitions
  - `exportfs -ra` — Apply exports
  - `showmount -e server` — Show available exports
  - NFSv3, NFSv4 (improved security, Kerberos auth)
- **NFS Client**
  - `mount -t nfs server:/path /mnt/point`
  - `/etc/fstab` for persistent mounts
  - automount / systemd mount units
- **NFS Protocols and Versions** — v3 (UDP/TCP), v4 (TCP, Kerberos, no portmapper)
- **rpcbind** — Port mapping service (NFSv3)
- **NFS Performance** — rsize/wsize (read/write block size), async vs sync
- **NFS Security** — Kerberos authentication, IP restrictions, root_squash
- **NFS Troubleshooting** — exportfs, showmount, rpcinfo, nfsstat

## 3.4 Samba and Windows Interoperability [Part 29]

- **SMB/CIFS** — Server Message Block protocol (Windows file sharing)
- **Samba** — Open-source SMB implementation for Linux
- **smbd** — SMB daemon (file sharing)
- **nmbd** — NetBIOS name resolution daemon
- **smbclient** — SMB client from Linux
- **smb.conf** — Samba configuration
  - [global] — Server settings
  - [share] — Shared directory definitions
- **Samba Users** — smbpasswd, pdbedit
- **Winbind** — Integrate with Windows domains
- **idmap** — UID/GID mapping between Linux and Windows
- **CUPS** — Common Unix Printing System (SMB printing)

## 3.5 RAID (Redundant Array of Independent Disks) [Part 30]

- **mdadm** — Linux software RAID management
- **RAID Levels**
  - RAID 0 (Striping) — Performance, no redundancy
  - RAID 1 (Mirroring) — Full redundancy, 50% storage
  - RAID 5 (Striping + Parity) — Min 3 drives, 1 drive fault tolerance
  - RAID 6 (Striping + Double Parity) — Min 4 drives, 2 drive fault tolerance
  - RAID 10 (Mirror + Stripe) — Min 4 drives, best performance + redundancy
- **RAID Array States** — clean, active, degraded, resyncing, failed
- **Creating RAID** — `mdadm --create /dev/md0 --level=1 --raid-devices=2 /dev/sd{b,c}`
- **Monitoring** — /proc/mdstat, mdadm --detail
- **Spare Drives** — Hot spares for automatic rebuild
- **Hardware RAID vs Software RAID** — RAID controller cards vs mdadm
- **Rebuild Process** — Automatic reconstruction after drive replacement
- **Chunk Size** — Stripe size for RAID 0/5/6/10

## 3.6 LVM (Logical Volume Manager) [Part 31]

- **LVM Architecture** — PV → VG → LV → Filesystem
- **Physical Volumes (PV)** — Physical disks/partitions
  - `pvcreate /dev/sdb`, `pvdisplay`, `pvs`
- **Volume Groups (VG)** — Pool of physical volumes
  - `vgcreate vgname /dev/sdb`, `vgdisplay`, `vgs`
- **Logical Volumes (LV)** — Virtual partitions carved from VGs
  - `lvcreate -L 10G -n lvname vgname`, `lvdisplay`, `lvs`
- **LVM Features**
  - Online resizing (grow LVs without downtime)
  - Thin provisioning (allocate on demand)
  - Snapshots (point-in-time copies)
  - Stripe/linear modes
  - RAID in LVM
- **LVM Snapshots** — Copy-on-Write (CoW) snapshots
  - `lvcreate -s -L 5G -n snap /dev/vgname/lvname`
  - Used for backups, testing
- **Resizing** — `lvextend`, `lvreduce`, `resize2fs`/`xfs_growfs`
- **Thin Provisioning** — Over-allocate storage, monitor actual usage
- **LVM Cache** — SSD cache for HDD volumes (dm-cache, dm-writecache)
- **LVM on RAID** — LV on top of mdadm for redundancy + flexibility
- **pvmove** — Migrate data between physical volumes (online)

## 3.7 Backup Strategies [Part 32]

- **3-2-1 Rule** — 3 copies, 2 different media, 1 offsite
- **Full Backup** — Complete copy of all data
- **Incremental Backup** — Only changes since last backup
- **Differential Backup** — Changes since last full backup
- **Backup Tools**
  - `rsync` — Delta transfer (only changed blocks)
    - `rsync -avz --delete source/ dest/`
    - `rsync -e ssh` — Over SSH
  - `tar` — Archive creation
  - `dd` — Low-level disk copy (bit-for-bit)
  - `borgbackup` — Deduplicated, encrypted, compressed backups
  - `restic` — Modern, fast, encrypted backup
  - `duplicity` — Encrypted incremental backups
  - `Timeshift` — System snapshot tool (Btrfs/LVM)
- **Backup Strategies** — RPO (Recovery Point Objective), RTO (Recovery Time Objective)
- **Backup Testing** — Regular restore verification
- **Offsite Backup** — Cloud storage, remote servers, tape rotation
- **Backup Rotation** — Grandfather-Father-Son (GFS), Tower of Hanoi
- **Cron-based Automation** — Automated backup scripts

## 3.8 System Monitoring [Part 33]

- **CPU Monitoring** — top, htop, mpstat, sar
- **Memory Monitoring** — free -h, vmstat, slabtop
  - Understanding buffer/cache vs used vs available
  - Swap usage and swappiness
- **Disk I/O** — iostat, iotop, dstat
- **Network Monitoring** — iftop, nethogs, ss, iptraf
- **Load Average** — 1min, 5min, 15min averages
  - Load < CPU cores = healthy; Load > CPU cores = overloaded
- **System Stats** — uptime, uname -a, lscpu, lsmem
- **Prometheus** — Time-series metrics collection
- **Grafana** — Metrics visualization and dashboards
- **Zabbix** — Enterprise monitoring solution
- **Nagios** — Classic monitoring and alerting
- **Collectd / Telegraf** — Metrics collection agents
- **SAR (System Activity Reporter)** — Historical performance data
- **dstat** — Versatile resource statistics tool
- **/proc/stat** — CPU statistics
- **/proc/meminfo** — Memory information
- **/proc/diskstats** — Disk I/O statistics
- **/proc/net/** — Network statistics

## 3.9 Process Management (Advanced) [Part 34]

- **Control Groups (cgroups)** — Resource limiting
  - CPU, memory, I/O, network bandwidth
  - cgroups v1 vs v2
- **nice / renice** — Process priority adjustment
- **Scheduling Policies** — SCHED_OTHER, SCHED_FIFO, SCHED_RR
- **Process Affinity** — CPU pinning (taskset, numactl)
- **NUMA (Non-Uniform Memory Access)** — Memory locality
- **Process Tracing** — strace (system calls), ltrace (library calls)
- **Core Dumps** — ulimit, core file patterns, gdb analysis
- **Process Resource Limits** — ulimit -a (soft/hard limits)

## 3.10 Advanced Shell Scripting [Part 36]

- **sed Advanced** — Multi-line operations, hold space, branching
- **awk Advanced** — Arrays, functions, BEGIN/END blocks, getline
- **Regular Expressions (Advanced)** — Lookahead, lookbehind, non-greedy
- **Bash Arrays** — Indexed and associative arrays
- **Here Documents / Here Strings**
- **Process Substitution** — <() and >()
- **Named Pipes (FIFOs)** — `mkfifo`, inter-process communication
- **File Locking** — flock for concurrent script safety
- **Error Handling** — set -euo pipefail, trap ERR
- **Logging in Scripts** — Structured logging, syslog
- **Parallel Execution** — xargs -P, GNU parallel, background jobs
- **Script Debugging** — bash -x, set -x, PS4 customization
- **Cron Integration** — Scripting for scheduled tasks
- **Configuration File Parsing** — Reading INI, YAML, JSON from bash

## 3.11 Inter-Process Communication (IPC)

- **IPC Mechanisms** — Methods for processes to communicate
- **Pipes (Unnamed)** — `command1 | command2`, one-way byte stream
  - Created with `pipe()` syscall
  - Parent creates pipe, fork() creates child sharing pipe file descriptors
  - Cannot be used between unrelated processes
- **Named Pipes (FIFOs)** — `mkfifo /path/fifo`, persistent in filesystem
  - Two-way communication possible (two FIFOs)
  - `ls -l` shows pipe type (p)
  - Blocking by default (open blocks until both ends connected)
- **Message Queues (POSIX / System V)** — Kernel-maintained message queues
  - `mq_open()`, `mq_send()`, `mq_receive()` (POSIX)
  - `msgget()`, `msgsnd()`, `msgrcv()` (System V)
  - Messages have priority, can be selected non-FIFO
  - Persistent until explicitly removed or system reboot
- **System V IPC** — Legacy IPC (shared memory, semaphores, message queues)
  - `ipcs` — Show IPC status (shared memory, semaphores, queues)
  - `ipcrm` — Remove IPC objects
  - Shared memory: `shmget()`, `shmat()`, `shmdt()`, `shmctl()`
  - Semaphores: `semget()`, `semop()`, `semctl()`
- **POSIX IPC** — Modern replacement (shared memory, semaphores, message queues)
  - Shared memory: `shm_open()`, `mmap()`, `shm_unlink()`
  - Named semaphores: `sem_open()`, `sem_wait()`, `sem_post()`, `sem_close()`
  - Lighter than System V, uses filesystem names
- **Shared Memory (mmap)** — Map files into process address space
  - `mmap()` — Map file or anonymous region
  - `munmap()` — Unmap region
  - Anonymous mapping for IPC between related processes
  - Fastest IPC method (no kernel copy, direct memory access)
- **memfd_create()** — Create anonymous file in memory (Linux 3.17+)
  - No filesystem backing, no path
  - Can be shared via file descriptors (sendfd over Unix socket)
  - Used by containers, QEMU, databases
- **eventfd** — Event notification via file descriptor
  - 64-bit counter, readable/writable
  - `eventfd()` syscall creates eventfd
  - Used for event loop notification (替代 pipe for wakeup)
  - Works with epoll, select, poll
- **signalfd** — Deliver signals via file descriptor
  - `signalfd()` — Create fd that reads signal info
  - Signals blocked with `sigprocmask()` then read from signalfd
  - Integrates with event loops (epoll)
- **timerfd** — Create timers via file descriptor
  - `timerfd_create()`, `timerfd_settime()`
  - Readable when timer expires
  - Integrates with epoll for event-driven programming
- **Unix Domain Sockets (UDS)** — Process communication over filesystem sockets
  - `AF_UNIX` / `AF_LOCAL` address family
  - `SOCK_STREAM` (reliable) or `SOCK_DGRAM` (datagram)
  - File: `/var/run/*.sock`, `/tmp/*.sock`
  - Faster than TCP (no network stack overhead)
  - Used by Docker, systemd, PostgreSQL, Redis
  - `socketpair()` — Create pair of connected UDS
- **D-Bus** — Desktop bus (inter-process communication system)
  - Message bus daemon (system bus + session bus)
  - Used by systemd, NetworkManager, PulseAudio, Bluetooth
  - `dbus-send`, `dbus-monitor` — CLI tools
  - XML interface definitions
  - Method calls, signals, properties
- **FUSE (Filesystem in Userspace)** — Implement filesystems in user space
  - `fuse` kernel module + user-space daemon
  - Used by: SSHFS, Flatpak, NTFS-3G, Google Drive mounts
  - Lower performance than kernel filesystems
  - `fusermount` — Mount/unmount FUSE filesystems
- **Pipes (process substitution)** — `<()` and `>()` in bash
  - Creates temporary named pipe, runs command in background
  - `diff <(sort file1) <(sort file2)` — Compare sorted files
- **inotify** — Filesystem event monitoring (Linux 2.6.13+)
  - `inotify_init()`, `inotify_add_watch()`
  - Events: IN_CREATE, IN_DELETE, IN_MODIFY, IN_MOVED_TO, etc.
  - `inotifywait` (from inotify-tools) — CLI event monitor
  - Used by: file managers, IDEs, log watchers, systemd path units
  - Limit: max_user_watches per user (sysctl fs.inotify.max_user_watches)
- **fanotify** — Filesystem access monitoring (Linux 2.9.37+)
  - System-wide file access monitoring (vs per-inode inotify)
  - Permission events: can allow/deny access
  - Used by: antivirus (ClamAV on-access scanning), DLP
  - `fanotify_mark()` — Add watch to mount point or directory tree
- **Netlink** — Kernel-userspace communication protocol
  - `AF_NETLINK` socket family
  - Used by: ip command, iptables, udev, NetworkManager
  - Multi-cast groups for kernel notifications
  - Variants: NETLINK_ROUTE, NETLINK_FIREWALL, NETLINK_GENERIC, NETLINK_AUDIT
- **copy_file_range()** — Zero-copy file copy in kernel (Linux 4.5+)
  - No userspace buffer copy
  - Used by NFS, sendfile on steroids
- **splice() / vmsplice()** — Zero-copy pipe-based data movement
  - `splice()` — Move data between pipe and file descriptor
  - `vmsplice()` — Move userspace data to pipe
  - Used by: Nginx sendfile, database log shipping
- **io_uring** — High-performance async I/O interface (Linux 5.1+)
  - Ring buffers for submission/completion (shared memory)
  - Supports: read, write, open, close, stat, fsync, connect, accept, send, recv
  - SQPoll mode: kernel polls submission queue (no syscalls)
  - Linked operations (chained I/O)
  - Fixed files and buffers for zero-allocation operation
  - Used by: databases (RocksDB), webservers (liburing)

## 3.12 Virtualization Technologies

- **Virtualization** — Running multiple OS instances on shared hardware
- **Hypervisor** — Software layer that manages virtual machines
  - **Type 1 (Bare-Metal)** — Runs directly on hardware (KVM, Xen, VMware ESXi, Hyper-V)
  - **Type 2 (Hosted)** — Runs on top of host OS (VirtualBox, VMware Workstation, QEMU)
- **KVM (Kernel-based Virtual Machine)** — Type 1 hypervisor built into Linux kernel
  - Kernel module: kvm-intel / kvm-amd (hardware virtualization: VT-x / AMD-V)
  - QEMU provides device emulation, KVM provides CPU/memory virtualization
  - `/dev/kvm` — KVM device file
  - `kvm-ok` — Check hardware virtualization support
- **QEMU (Quick Emulator)** — Full system emulator
  - Can run standalone (software emulation, slow) or with KVM (fast)
  - Device models: virtio, e1000, virtio-net, virtio-blk, IDE, SCSI
  - QMP (QEMU Machine Protocol) — JSON-based control interface
  - `-m 4G -smp 4 -enable-kvm -drive file=disk.qcow2`
- **libvirt** — Virtualization management API
  - Manages KVM, QEMU, Xen, LXC, VMware, VirtualBox
  - `virsh` — CLI for libvirt
    - `virsh list --all`, `virsh start/stop/destroy`, `virsh dominfo`, `virsh edit`
    - `virsh snapshot-create`, `virsh snapshot-revert`
  - Libvirt daemon: `libvirtd`
  - Storage pools: directory, lvm, iscsi, rbd
  - Virtual networks: NAT, bridged, macvtap
- **Virtual Machine Formats** — qcow2 (copy-on-write, snapshots), raw, vmdk, vhd
- **Virtio Drivers** — Paravirtualized I/O (high performance)
  - virtio-net, virtio-blk, virtio-scsi, virtio-balloon, virtio-serial
  - Requires guest OS support (standard in modern Linux)
- **PCI Passthrough (VFIO)** — Assign physical PCI devices to VMs
  - IOMMU (VT-d / AMD-Vi) required
  - `vfio-pci` kernel module
  - Used for GPU passthrough, NVMe passthrough
- **SR-IOV (Single Root I/O Virtualization)** — Hardware-level network virtualization
  - Physical NIC presents multiple virtual NICs (VFs)
  - Each VF assigned to a different VM
  - Near-native performance
- **Live Migration** — Move running VM between hosts without downtime
  - Pre-copy migration: iteratively copy dirty pages
  - Post-copy migration: fault pages on access
  - Requires shared storage (NFS, SAN, Ceph)
- **Xen** — Open-source hypervisor (Type 1)
  - Dom0 (privileged domain) + DomU (unprivileged guest VMs)
  - HVM (hardware-virtualized) and PV (paravirtualized) modes
  - Used by: AWS (early), Citrix XenServer, Oracle VM
- **LXC (Linux Containers)** — System containers (full OS environment)
  - Uses cgroups + namespaces (not virtualization per se)
  - Lightweight alternative to VMs
  - `lxc-create`, `lxc-start`, `lxc-stop`, `lxc-destroy`
  - LXD — Enhanced LXC with REST API, image management
- **VM Templates and Cloning** — Golden images for rapid deployment
  - virt-sysprep — Prepare VM image for cloning
  - Cloud-init — First-boot configuration (user data, SSH keys)
- **Nested Virtualization** — Running VMs inside VMs
  - `kvm_intel nested=Y` or `kvm_amd nested=1`
  - Used in CI/CD (Kubernetes in VMs), training environments
- **Memory Overcommit** — Allocating more virtual memory than physical
  - Balloon drivers (virtio-balloon) return unused memory
  - KSM (Kernel Same-page Merging) deduplicate identical pages
  - Swap, page sharing
- **CPU Pinning** — Assign vCPUs to physical cores (performance isolation)
  - `virsh vcpupin`, `taskset`, `numactl`
- **NUMA-Aware Virtualization** — Pin VM memory and vCPUs to NUMA nodes
  - `numactl --cpunodebind=0 --membind=0`
- **Virtual Disks** — qcow2 (snapshots, thin provisioning), raw (best performance)
  - `qemu-img create`, `qemu-img info`, `qemu-img convert`
- **Cloud Hypervisor** — Lightweight Rust-based VMM (Virtual Machine Monitor)
  - Minimal footprint, designed for cloud workloads

---

# Level 4: Enterprise Services

## 4.1 Automation with Ansible [Part 37]

- **Configuration Management** — Define and maintain system state declaratively
- **Ansible Architecture** — Agentless, SSH-based, push model
- **Playbooks** — YAML files defining automation tasks
  - Tasks, handlers, variables, templates, loops, conditionals
- **Inventory** — Host and group definitions (static/dynamic)
- **Modules** — Reusable units of work (apt, yum, copy, template, service, user)
- **Roles** — Reusable playbook components
- **Variables** — Facts, host vars, group vars, extra vars, registered vars
- **Handlers** — Triggered tasks (restart service on config change)
- **Templates** — Jinja2 templates for configuration files
- **Tags** — Selective task execution
- **Vault** — Encrypted secrets management
- **Galaxy** — Community role collection
- **Ad-Hoc Commands** — Quick one-off operations
- **Idempotency** — Run multiple times with same result
- **Error Handling** — ignore_errors, block/rescue/always
- **Facts** — Gathered system information

## 4.2 Container Basics [Part 38]

- **Containers** — Lightweight, isolated process environments
- **Container vs Virtual Machine** — Shared kernel, less overhead, faster startup
- **Docker** — Most popular container platform
  - **Dockerfile** — Build instructions for images
  - **Image** — Read-only template for containers
  - **Container** — Running instance of an image
  - **Registry** — Image storage (Docker Hub, GHCR, ECR)
  - **Docker Compose** — Multi-container applications
  - **Volumes** — Persistent storage
  - **Networks** — Container networking (bridge, host, overlay)
  - **Docker CLI** — run, build, ps, images, exec, logs, stop, rm
- **Podman** — Daemonless, rootless container engine
  - OCI-compatible, Docker CLI compatible
  - Rootless by default (more secure)
  - Quadlet for systemd integration
  - Pods (Kubernetes-style)
  - Buildah (image building), Skopeo (image inspection)
- **Container Images**
  - Layers (union filesystem / OverlayFS)
  - Base images, multi-stage builds
  - Image tags and digests
  - .dockerignore
- **OCI (Open Container Initiative)** — Standard for container format and runtime
- **Container Runtimes** — containerd, CRI-O, runc
- **Image Registries** — Docker Hub, GitHub Container Registry, private registries
- **Container Security** — Least privilege, no root, image scanning, signing

### Container Ecosystem Deep Dive

- **containerd** — Industry-standard container runtime (CNCF graduated), `ctr` CLI, CRI interface, shim v2 API
- **CRI-O** — Kubernetes-native container runtime, `crictl` CLI, OCI-compatible
- **Buildah** — Daemonless container image builder, rootless image building
- **Skopeo** — Container image operations tool (inspect, copy, delete, list-tags)
- **Container Image Signing (cosign/Sigstore)** — Keyless signing, Fulcio, Rekor, supply chain integrity
- **SBOM (Software Bill of Materials)** — SPDX, CycloneDX formats, `syft` tool
- **Trivy** — Vulnerability and misconfiguration scanner for images and filesystems
- **Netdata** — Real-time infrastructure monitoring with per-second granularity

## 4.3 Web Servers [Part 39]

- **Apache HTTP Server (httpd)** — Most widely used web server
  - Virtual Hosts — Multiple sites on one server
  - .htaccess — Directory-level configuration
  - Modules — mod_ssl, mod_rewrite, mod_proxy
  - MPM (Multi-Processing Module) — prefork, worker, event
  - Configuration: /etc/apache2/ or /etc/httpd/
- **Nginx** — High-performance web server and reverse proxy
  - Event-driven, non-blocking architecture
  - Reverse proxy, load balancer, mail proxy
  - Configuration: /etc/nginx/nginx.conf
  - Server blocks (virtual hosts)
  - Location blocks (URL matching)
  - Proxy_pass for upstream servers
  - SSL/TLS termination
- **Caddy** — Automatic HTTPS web server
- **Virtual Hosts** — Hosting multiple domains on one server
- **SSL/TLS Certificates** — Let's Encrypt (Certbot), commercial certs
  - Certificate chain: Root CA → Intermediate → Server cert
  - ACME protocol for automatic certificate management
- **CGI / FastCGI / PHP-FPM** — Dynamic content processing
- **Reverse Proxy** — Backend request forwarding, header manipulation
- **Load Balancing** — Round-robin, least-connections, IP hash
- **Web Server Hardening** — Disable directory listing, restrict methods, security headers

## 4.4 Databases [Part 40]

- **MariaDB** — MySQL fork (default on many distros)
- **MySQL** — Popular relational database
- **PostgreSQL** — Advanced open-source relational database (MVAC, JSONB, extensions)
- **SQLite** — Embedded, file-based database
- **Key Concepts**
  - SQL (Structured Query Language)
  - ACID (Atomicity, Consistency, Isolation, Durability)
  - Normalization (1NF, 2NF, 3NF, BCNF)
  - Indexing (B-tree, hash, GiST)
  - Views, stored procedures, triggers
  - Replication (master-slave, master-master)
  - Connection pooling
  - Backups (mysqldump, pg_dump, logical vs physical)
- **NoSQL** — MongoDB, Redis, Cassandra (overview)
- **Database Administration**
  - User management and privileges
  - Performance tuning (query optimization, slow query log)
  - Monitoring (pt-query-digest, pg_stat_activity)
  - Schema management and migrations

## 4.5 LDAP and Centralized Authentication [Part 41]

- **LDAP (Lightweight Directory Access Protocol)** — Directory service protocol
- **OpenLDAP** — Open-source LDAP implementation
- **Active Directory** — Microsoft's directory service
- **SSSD (System Security Services Daemon)** — PAM/NSS bridge for centralized auth
  - Caches credentials for offline login
  - Supports LDAP, Kerberos, AD backends
  - Configuration: /etc/sssd/sssd.conf
- **PAM (Pluggable Authentication Modules)** — Authentication framework
  - PAM configuration: /etc/pam.d/
  - Modules: pam_unix, pam_ldap, pam_sss, pam_cracklib, pam_tally2
  - Control flags: required, requisite, sufficient, optional
  - Stacks: auth, account, password, session
- **NSS (Name Service Switch)** — User/group lookup
  - /etc/nsswitch.conf — Lookup order (files, sss, ldap)
- **Kerberos** — Ticket-based authentication
  - KDC (Key Distribution Center), tickets, realms
  - kinit, klist, kdestroy
- **SSSD Configuration** — Domain providers, access control, sudo rules from LDAP
- **realm / realmd** — Domain join tool
- **Home Directory Creation** — pam_mkhomedir

## 4.6 DNS Server Administration [Part 42]

- **BIND (named)** — Most widely deployed DNS server
  - named.conf.options, named.conf.local, named.conf.default-zones
  - Zone files — SOA, NS, A, AAAA, MX, CNAME records
  - Forwarders, recursion, caching
  - ACLs and TSIG keys (secure updates)
  - Split-horizon DNS
  - views (internal vs external)
- **Unbound** — Validating, recursive, caching resolver
- **PowerDNS** — Authoritative DNS with multiple backends
- **dnsmasq** — Lightweight DNS + DHCP
- **BIND Security** — DNSSEC, response rate limiting, query logging
- **Zone Transfers** — Primary/secondary DNS replication
- **Dynamic DNS** — DDNS updates from clients

## 4.7 DHCP Server [Part 43]

- **DHCP (Dynamic Host Configuration Protocol)** — Automatic IP configuration
- **DHCP Process** — DORA (Discover, Offer, Request, Acknowledge)
- **ISC DHCP Server** — Traditional DHCP server
  - /etc/dhcp/dhcpd.conf
  - Subnet declarations, ranges, options
  - Static reservations (MAC → IP)
- **Kea** — Modern ISC DHCP replacement
- **DHCP Relay** — Forward DHCP across subnets (dhcrelay)
- **DHCP Options** — Router, DNS, domain name, lease time
- **DHCP Logging** — /var/log/syslog (dhcpd)

## 4.8 Mail Servers [Part 44]

- **Postfix** — Fast, secure MTA (Mail Transfer Agent)
  - Configuration: /etc/postfix/main.cf
  - myhostname, mydomain, mydestination, relayhost
  - SMTP, submission (587), SMTPS (465)
- **Dovecot** — IMAP/POP3 server (Mail Delivery Agent)
  - Mailbox formats: Maildir, mbox
- **Sendmail** — Legacy MTA (largely replaced)
- **Spam Filtering** — SpamAssassin, Rspamd
- **DKIM / SPF / DMARC** — Email authentication
- **Mailing Lists** — Mailman
- **Mail Queue** — postqueue, postsuper
- **Relay Configuration** — Sending through external SMTP (Gmail, SendGrid)

## 4.9 Proxy and Reverse Proxy [Part 45]

- **Forward Proxy** — Client-side proxy (Squid)
- **Reverse Proxy** — Server-side proxy (Nginx, HAProxy)
- **Squid** — Caching HTTP proxy
  - ACLs for access control
  - Cache configuration
  - Transparent proxy mode
- **Nginx as Reverse Proxy** — proxy_pass, upstream blocks
- **HAProxy** — High-performance load balancer
  - TCP and HTTP modes
  - Backend servers, health checks
  - Load balancing algorithms: roundrobin, leastconn, source, uri
  - Stats page for monitoring
- **Proxy Protocols** — HTTP, HTTPS, SOCKS5
- **Content Caching** — Varnish (HTTP accelerator)
- **SSL Termination** — Offload TLS at proxy
- **Web Application Firewall (WAF)** — ModSecurity, NAXSI

## 4.10 Monitoring and Alerting [Part 46]

- **Nagios** — Classic monitoring (Core, XI)
  - Plugins, services, hosts, notifications
- **Zabbix** — Enterprise monitoring (agents, proxies, server)
  - Templates, triggers, escalation
- **Prometheus** — Time-series database and monitoring
  - Pull-based metrics (HTTP scrape endpoint)
  - PromQL query language
  - Alertmanager for alerts
  - Exporters (node_exporter, mysqld_exporter, etc.)
  - Service discovery
- **Grafana** — Visualization and dashboards
  - Data sources (Prometheus, Loki, Elasticsearch)
  - Panels, variables, alerts
- **Loki** — Log aggregation (like Prometheus but for logs)
- **ELK Stack** — Elasticsearch, Logstash, Kibana (centralized logging)
- **Fluentd / Fluent Bit** — Log forwarders
- **OpenTelemetry** — Vendor-neutral observability framework
- **SNMP Monitoring** — Network device monitoring
- **Uptime Monitoring** — blackbox_exporter, external checks
- **Alerting Best Practices** — Avoid alert fatigue, actionable alerts, escalation policies
- **SLI / SLO / SLA** — Service Level Indicators, Objectives, Agreements
- **Thanos** — Highly available Prometheus with global query and long-term storage
- **Cortex** — Horizontally-scalable Prometheus, multi-tenant metrics
- **Jaeger** — Distributed tracing system (OpenTracing/OpenTelemetry compatible)
- **Zipkin** — Distributed trace visualization
- **OpenTelemetry Collector** — Vendor-neutral telemetry pipeline (receivers, processors, exporters)
- **Grafana Beyla** — eBPF auto-instrumentation for zero-code metrics

## 4.11 Performance Tuning [Part 47]

- **CPU Tuning** — Governor, frequency scaling, IRQ affinity
- **Memory Tuning** — Swappiness, vm.dirty_ratio, huge pages
  - Transparent HugePages (THP)
  - HugeTLB filesystem (hugetlbfs)
  - NUMA balancing
- **I/O Scheduler** — mq-deadline, bfq, none (NVMe), kyber
- **Network Tuning** — TCP window size, backlog, congestion control (BBR, CUBIC)
  - /proc/sys/net/ parameters
  - sysctl configuration
- **Filesystem Tuning** — Mount options (noatime, commit, barrier)
- **Disk Performance** — fio, dd, hdparm, smartctl
- **Benchmarking Tools** — sysbench, perf, flamegraphs
- **Profile-Guided Optimization** — System profiling before tuning
- **Resource Limits** — ulimit, cgroups, /etc/security/limits.conf

---

## 4.12 High Availability and Clustering [Part 48]

- **High Availability (HA)** — Minimizing downtime through redundancy
- **Single Point of Failure (SPOF)** — Component whose failure brings down the system
- **Keepalived** — VRRP-based floating IP failover
  - Virtual Router Redundancy Protocol (VRRP)
  - Master/Backup states
  - Health check scripts
  - Virtual IP (VIP) migration
- **HAProxy** — Load balancer with health checks
  - Frontend (incoming traffic), Backend (servers)
  - ACLs (access control lists)
  - Stats socket for runtime management
  - Connection draining
- **Pacemaker** — Cluster Resource Manager (CRM)
  - Resources: primitives, groups, clones, masters/slaves
  - Constraints: colocation, order, location
  - Resource agents (OCF, LSB, systemd)
- **Corosync** — Cluster communication and membership
  - Ring protocol, quorum, votequorum
  - Message ordering and delivery
- **PCS (Pacemaker/Corosync Shell)** — Management CLI
  - `pcs cluster setup`, `pcs resource create`
  - `pcs status`, `pcs node standby`
- **STONITH (Shoot The Other Node In The Head)** — Fencing
  - Prevents split-brain
  - IPMI, power switches, cloud API based
- **Quorum** — Minimum nodes for cluster operation (majority voting)
- **Split-Brain** — Network partition causing dual-active (data corruption risk)
- **Active/Passive** — One node active, other standby
- **Active/Active** — All nodes serve traffic simultaneously
- **GFS2 / OCFS2** — Cluster filesystems for shared storage
- **DLM (Distributed Lock Manager)** — Cluster-wide locking

## 4.13 Security Hardening and Auditing [Part 49]

- **Defense in Depth** — Multiple security layers
- **CIS Benchmarks** — Center for Internet Security hardening guides
- **Lynis** — Security auditing tool
  - `lynis audit system`
- **OpenSCAP** — Security compliance scanning
  - XCCDF profiles, OVAL definitions
- **auditd** — Linux Audit Framework
  - /etc/audit/audit.rules
  - Monitor file access, syscalls, user actions
  - ausearch, aureport
- **AIDE (Advanced Intrusion Detection Environment)** — File integrity monitoring
- **fail2ban** — Brute-force protection (ban IPs after failed attempts)
- **ClamAV** — Antivirus for Linux
- **Port Security** — Unnecessary services, netstat/ss auditing
- **Password Policies** — pam_pwquality, password aging, complexity
- **SSH Hardening** — Key-only auth, port change, rate limiting
- **Firewall Hardening** — Default deny, minimal open ports
- **Kernel Hardening** — sysctl (net.ipv4.conf.all.accept_redirects = 0, etc.)
- **File Integrity Monitoring** — Tripwire, AIDE, OSSEC
- **Privilege Escalation Prevention** — Sudo auditing, capabilities, AppArmor/SELinux
- **Encrypted Filesystems** — LUKS, dm-crypt
- **TLS/SSL** — Certificate management, protocol versions, cipher suites
- **Vulnerability Scanning** — OpenVAS, Nessus

---

# Level 5: Cloud & Modern DevOps

## 5.1 Cloud Infrastructure [Part 50]

- **Cloud Service Models** — IaaS, PaaS, SaaS
- **AWS (Amazon Web Services)**
  - EC2, S3, VPC, IAM, RDS, Lambda, EKS, EBS
  - Regions, Availability Zones, Edge Locations
- **GCP (Google Cloud Platform)**
  - Compute Engine, Cloud Storage, VPC, IAM, GKE, Cloud Functions
- **Azure (Microsoft Azure)**
  - Virtual Machines, Blob Storage, VNet, Azure AD, AKS
- **Cloud-Native** — Designed for cloud environments
- **Multi-Cloud** — Using multiple cloud providers
- **Hybrid Cloud** — Mix of on-premises and cloud
- **Cloud Networking** — VPC, subnets, security groups, load balancers, NAT gateways
- **Cloud Storage** — Object, block, file storage
- **Cloud IAM** — Identity and access management, RBAC, service accounts
- **Cloud Monitoring** — CloudWatch, Stackdriver, Azure Monitor

## 5.2 Infrastructure as Code (IaC) [Part 51]

- **Terraform** — Declarative infrastructure provisioning
  - HCL (HashiCorp Configuration Language)
  - Providers, resources, data sources, variables, outputs
  - State management (local, remote, S3, Terraform Cloud)
  - `terraform init`, `terraform plan`, `terraform apply`, `terraform destroy`
  - Modules for reusability
  - Workspaces for environments
  - Import existing resources
- **OpenTofu** — Open-source Terraform fork (Linux Foundation)
- **Pulumi** — IaC using general-purpose languages (Python, TypeScript, Go)
- **CloudFormation** — AWS-native IaC
- **ARM Templates / Bicep** — Azure-native IaC
- **Ansible** — Procedural configuration management (vs Terraform's declarative)
- **Best Practices** — Version control, plan before apply, state locking, drift detection

## 5.3 Kubernetes Administration [Part 52]

- **Kubernetes (K8s)** — Container orchestration platform
- **Architecture**
  - Control Plane: API server, etcd, scheduler, controller manager
  - Worker Nodes: kubelet, kube-proxy, container runtime
- **Core Objects**
  - Pod — Smallest deployable unit (1+ containers)
  - Service — Stable network endpoint (ClusterIP, NodePort, LoadBalancer)
  - Deployment — Declarative pod updates, rolling updates
  - ReplicaSet — Desired pod count
  - ConfigMap / Secret — Configuration and sensitive data
  - Namespace — Virtual cluster partitioning
  - Ingress — HTTP routing (Ingress controllers: Nginx, Traefik)
  - PersistentVolume (PV) / PersistentVolumeClaim (PVC) — Storage
  - StatefulSet — Stateful applications (databases, message queues)
  - DaemonSet — Run on every node
  - Job / CronJob — Batch and scheduled workloads
- **kubectl** — Kubernetes CLI
  - `kubectl get`, `kubectl describe`, `kubectl apply`, `kubectl delete`
  - `kubectl logs`, `kubectl exec`, `kubectl port-forward`
- **Helm** — Kubernetes package manager
  - Charts, values.yaml, releases
  - `helm install`, `helm upgrade`, `helm rollback`
- **Networking** — CNI plugins (Calico, Cilium, Flannel)
- **RBAC** — Role-Based Access Control
- **Network Policies** — Pod-to-pod traffic control
- **Auto-scaling** — HPA (Horizontal Pod Autoscaler), VPA, Cluster Autoscaler
- **Service Mesh** — Istio, Linkerd (mTLS, traffic management)
- **GitOps** — ArgoCD, Flux (Git as source of truth for deployments)

## 5.4 CI/CD Pipelines [Part 53]

- **CI (Continuous Integration)** — Automated build and test on every commit
- **CD (Continuous Delivery/Deployment)** — Automated release pipeline
- **GitHub Actions** — CI/CD built into GitHub
  - Workflows, jobs, steps, actions
  - YAML configuration
- **GitLab CI/CD** — Integrated with GitLab
  - .gitlab-ci.yml, stages, runners
- **Jenkins** — Open-source automation server
  - Pipelines (declarative/scripted)
  - Plugins, agents, shared libraries
- **ArgoCD** — GitOps continuous delivery for Kubernetes
- **Flux** — GitOps operator for Kubernetes
- **Pipeline Stages** — Build, test, scan, deploy, verify
- **Infrastructure Pipeline** — Terraform plan/apply in CI/CD
- **Quality Gates** — Code coverage, security scanning, performance tests
- **Rollback Strategies** — Blue-green, canary, rolling updates

## 5.5 Advanced Configuration Management [Part 54]

- **Puppet** — Declarative configuration management (agent-based)
  - Manifests, modules, Hiera (data), Facter (facts)
- **Salt (SaltStack)** — Event-driven configuration management
  - States, grains, pillars, reactors
  - ZeroMQ communication
- **Chef** — Ruby-based configuration management
  - Recipes, cookbooks, InSpec (compliance)
- **Comparison** — Ansible (agentless, push) vs Puppet (agent, pull) vs Salt (hybrid) vs Chef (agent, pull)

## 5.6 Immutable Infrastructure [Part 55]

- **Packer** — Build machine images (VM images, container images)
  - Templates, builders, provisioners, post-processors
  - AMI, Vagrant box, Docker image outputs
- **Golden Images** — Pre-baked, tested server images
- **Image Pipeline** — Build → Test → Publish → Deploy
- **Immutable vs Mutable** — Replace servers vs patch in place
- **Nix / NixOS** — Reproducible, declarative package management

## 5.7 Observability Deep Dive [Part 56]

- **Three Pillars** — Metrics, Logs, Traces
- **Metrics** — Quantitative measurements over time
  - RED method: Rate, Errors, Duration
  - USE method: Utilization, Saturation, Errors
  - Four Golden Signals: Latency, Traffic, Errors, Saturation
- **Logs** — Timestamped event records
  - Structured logging (JSON), log levels
  - Centralized logging pipelines
- **Traces** — Distributed request tracking
  - OpenTelemetry, Jaeger, Zipkin
  - Span, trace ID, propagation
- **Prometheus** — Metrics collection and alerting
  - PromQL, recording rules, alerting rules
- **Grafana** — Dashboarding and visualization
- **Loki** — Log aggregation (PromQL-like queries)
- **OpenTelemetry** — Vendor-neutral telemetry framework
  - OTLP, SDKs, collectors, auto-instrumentation
- **eBPF-based Observability** — Cilium Hubble, Pixie, Falco
- **Thanos** — Highly available Prometheus with global query
  - Long-term storage in object storage (S3, GCS)
  - Sidecar, Store, Query, Compactor, Ruler components
  - Downsampling for old data
- **Cortex** — Horizontally-scalable Prometheus, multi-tenant metrics as a service
  - Blocks storage or chunks storage
  - Distributor, Ingester, Querier, Compactor
- **Prometheus Alerting Rules Deep Dive** — Recording rules, Alertmanager grouping/inhibition/silencing, multi-window burn rate alerts
  - PromQL aggregation, rate, histogram_quantile
- **Jaeger** — Distributed tracing system with agent, collector, query, UI components
  - OpenTracing / OpenTelemetry compatible
  - Trace sampling: head-based, tail-based
  - Service dependency graph
- **Zipkin** — Distributed trace visualization with Brave instrumentation
  - Trace collection, storage, UI
- **OpenTelemetry Collector** — Vendor-neutral pipeline with receivers, processors, exporters
  - Receivers (OTLP, Jaeger, Prometheus, Zipkin)
  - Processors (batch, transform, tail sampling)
  - Exporters (Prometheus, Loki, Jaeger, OTLP)
  - Declarative configuration: otel-collector-config.yaml
- **Grafana Beyla** — eBPF auto-instrumentation, zero-code HTTP/gRPC metrics
  - Automatic RED metrics for any process
  - Trace-to-metrics correlation
- **Cilium Hubble** — eBPF network observability, service-to-service flow logs
  - Network policy audit mode
  - `hubble observe`, `hubble status`
  - Prometheus metrics export
- **Tetragon** — eBPF runtime security with process monitoring and file access auditing
  - Network connection monitoring
  - Security policies via CRDs

## 5.8 Modern Linux Networking [Part 57]

- **eBPF (Extended Berkeley Packet Filter)** — Programmable kernel hooks
  - XDP (eXpress Data Path) for high-performance networking
  - TC (Traffic Control) programs
  - Tracing, security, networking use cases
  - BCC (BPF Compiler Collection), bpftrace
- **Cilium** — eBPF-based networking and security for Kubernetes
- **WireGuard** — Modern, fast VPN protocol
  - Simpler than IPsec, kernel-native
  - wg-quick for configuration
- **VXLAN (Virtual Extensible LAN)** — Layer 2 overlay on Layer 3
  - Used in container networking, SDN
- **Network Namespaces** — Isolated network stacks
- **VETH Pairs** — Virtual ethernet connections
- **Linux Bridges** — Software switches (br0)
- **Policy-Based Routing** — Route based on packet characteristics
- **Traffic Shaping** — tc (traffic control), HTB, tbf
  - Bandwidth limiting, prioritization
- **SDN (Software-Defined Networking)** — Open vSwitch, OpenFlow
- **Calico** — BGP-based pod networking, network policy, IP-in-IP/VXLAN encapsulation, eBPF dataplane
  - BGP peering with physical network
  - `calicoctl` — CLI for Calico
- **Flannel** — Simple overlay networking with VXLAN and host-gw backends
  - VXLAN backend — Encapsulation for cross-node pod traffic
  - host-gw backend — Direct routing (no encapsulation, same L2)
  - `etcd` or Kubernetes API for subnet lease management
- **CNI (Container Network Interface)** — Kubernetes networking plugin standard, IPAM
  - `CNI_COMMAND` — ADD, DEL, CHECK, VERSION
  - IPAM (IP Address Management) — dhcp, host-local, whereabouts

## 5.9 Secrets Management [Part 58]

- **HashiCorp Vault** — Centralized secrets management
  - KV, transit, PKI, database engines
  - Policies, auth methods (LDAP, AppRole, Kubernetes)
  - Dynamic secrets
- **SOPS (Secrets OPerationS)** — Encrypted secrets in files
  - age, KMS, GPG encryption
  - Decrypt on the fly
- **Sealed Secrets** — Kubernetes-native encrypted secrets
- **Kubernetes Secrets** — Base64-encoded (not encrypted by default)
  - External Secrets Operator
- **Environment Variable Secrets** — Simple but less secure
- **Ansible Vault** — Encrypted variables in playbooks
- **Secrets Best Practices** — Never in git, rotate regularly, least privilege, audit access

## 5.10 Site Reliability Engineering (SRE) [Part 59]

- **SLIs (Service Level Indicators)** — Quantitative measures of service behavior
  - Request latency, error rate, throughput, availability
- **SLOs (Service Level Objectives)** — Target values for SLIs
  - e.g., 99.9% availability, p99 latency < 200ms
- **SLAs (Service Level Agreements)** — Business contracts defining SLOs with consequences
- **Error Budgets** — Allowed unreliability (1 - SLO)
  - Burn rate, multi-window burn rate alerts
- **Incident Management** — On-call, PagerDuty, incident response
  - Blameless postmortems
  - Mean Time to Detect (MTTD), Mean Time to Recover (MTTR)
- **Capacity Planning** — Forecasting resource needs
- **Chaos Engineering** — Netflix Chaos Monkey, Litmus
  - Testing system resilience through controlled failures
- **Runbooks** — Step-by-step operational procedures
- **Toil Reduction** — Automating repetitive manual work

---

# Level 6: Deep Internals

## 6.1 Filesystem Internals [Part 61]

- **Inodes** — Data structure representing files (metadata without name)
  - inode number, size, permissions, timestamps, block pointers
  - Direct, indirect, double-indirect, triple-indirect blocks
  - inode exhaustion (no more files possible even with free space)
- **Superblock** — Filesystem metadata (total blocks, free blocks, block size)
- **Journaling** — Write-ahead logging for crash recovery
  - ext4: journaled metadata (data=ordered, data=writeback, data=journal)
  - XFS: journaling built-in
- **Filesystem Types**
  - **ext4** — Default, stable, journaled, extents
  - **XFS** — High performance, large files, parallel I/O, online defrag
  - **Btrfs** — Copy-on-Write, snapshots, subvolumes, RAID, checksums, compression
  - **ZFS** — Enterprise: CoW, checksums, RAIDZ, snapshots, dedup, compression, ARC cache
  - **tmpfs** — RAM-based temporary filesystem
  - **sysfs, procfs** — Virtual filesystems
- **Virtual Filesystem (VFS)** — Kernel abstraction layer for all filesystem types
  - Common interface: open, read, write, close
  - inode, dentry, file structures
- **Disk Layout** — Boot block, superblock, inode table, data blocks
- **Block Groups** — Grouping of inodes and data blocks (ext4)
- **File Recovery** — extundelete, photorec, testdisk
- **Filesystem Check** — fsck (ext4), xfs_repair, btrfs check, zpool scrub
- **Filesystem Mounting** — mount, umount, /etc/fstab, fstab options
  - Options: ro/rw, noexec, nosuid, nodev, noatime, barrier, commit
- **OverlayFS** — Union filesystem (used in containers)
  - Lower layer (read-only), upper layer (read-write), merged view
- **Bind Mounts** — `mount --bind dir1 dir2`

## 6.2 Memory Management [Part 62]

- **Virtual Memory** — Process address space abstraction
  - Page tables: virtual → physical mapping
  - Demand paging: pages loaded on access
  - Copy-on-Write: shared pages until modified
- **Pages and Page Frames** — Fixed-size memory blocks (4KB typical)
- **Page Cache** — Cache for file data in RAM
  - `free -h` shows buff/cache
  - Reclaimable when needed
- **Anonymous Memory** — Heap, stack (not backed by files)
- **Swap** — Disk space used as virtual RAM
  - Swap partitions vs swap files
  - Swappiness (0-100): tendency to swap vs drop cache
- **OOM Killer (Out-of-Memory)** — Kills processes when memory exhausted
  - oom_score, oom_score_adj
  - /proc/[pid]/oom_score
- **Memory Zones** — ZONE_DMA, ZONE_NORMAL, ZONE_HIGHMEM
- **NUMA (Non-Uniform Memory Access)** — Memory locality aware
  - numactl, numastat, numad
- **Huge Pages** — Larger page sizes (2MB, 1GB) for TLB efficiency
  - Transparent HugePages (THP)
  - HugeTLB filesystem (hugetlbfs)
- **Memory Reclaim** — kswapd, direct reclaim, LRU lists
- **Slab Allocator** — Kernel object caching (slabtop, /proc/slabinfo)
- **Overcommit** — Memory allocation policies
  - vm.overcommit_memory, vm.overcommit_ratio
- **Memory Diagnostics** — free, vmstat, /proc/meminfo, slabtop, smem

## 6.3 eBPF and Modern Tracing [Part 63]

- **eBPF (Extended Berkeley Packet Filter)** — Programmable kernel sandbox
  - Safely run programs in kernel space
  - Verified for safety (no infinite loops, no crashes)
- **eBPF Programs** — Attached to kernel hooks
  - Kprobes/kretprobes — Function entry/exit
  - Tracepoints — Static kernel instrumentation
  - XDP (eXpress Data Path) — Network packet processing
  - TC (Traffic Control) — Packet filtering
  - cgroups — Resource limiting hooks
  - USDT — User-space static tracepoints
- **BCC (BPF Compiler Collection)** — Python/C tools for eBPF
  - biolatency, execsnoop, opensnoop, tcpconnect, runqlat
- **bpftrace** — High-level eBPF tracing language
- **BPF Maps** — Data structures shared between kernel and user space
  - Hash maps, arrays, LRU, ring buffers
- **eBPF Use Cases**
  - Networking (Cilium, XDP firewalls)
  - Observability (metrics, tracing)
  - Security (Falco, seccomp profiles)
  - Performance analysis (flame graphs, latency)
- **libbpf** — Low-level eBPF library
- **CO-RE (Compile Once, Run Everywhere)** — Portable eBPF programs
- **bpftrace One-Liners** — Quick kernel tracing examples:
  - `bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }'`
  - `bpftrace -e 'profile:hz:99 { @[kstack] = count(); }'` — CPU profiler
  - `bpftrace -e 'tracepoint:block:block_rq_complete { @usecs = hist(args->nr_sector); }'`
  - `bpftrace -e 'kprobe:tcp_connect { @[comm] = count(); }'` — TCP connection tracing
- **BCC Tools Reference** — Pre-built eBPF tools:
  - `opensnoop` — Trace file opens
  - `execsnoop` — Trace new processes
  - `tcpconnect` / `tcpaccept` — Trace TCP connections
  - `biolatency` — Block I/O latency histogram
  - `biotop` — Block I/O by process
  - `cachestat` — Page cache hit/miss
  - `ext4slower` / `xfs_slower` — Slow filesystem ops
  - `tcpdrop` — Trace TCP drops with stack
  - `runqlat` — CPU run queue latency
  - `profile` — CPU stack profiler
  - `funccount` — Function call counting
  - `trace` — Function tracing with arguments
  - `argdist` — Function argument distribution
  - `funclatency` — Function latency distribution
- **Falco** — Runtime threat detection with kernel-level syscall monitoring and rule-based threat detection
- **Pixie** — eBPF-based observability for Kubernetes with auto-instrumentation and PxL scripting

## 6.4 Linux Namespaces [Part 64]

- **Namespaces** — Kernel-level isolation of global resources
- **7 Namespace Types**
  - **PID** — Isolated process ID space (container thinks it's PID 1)
  - **Network (NET)** — Isolated network stack (interfaces, routes, iptables)
  - **Mount (MNT)** — Isolated filesystem view
  - **UTS** — Isolated hostname and domain
  - **IPC** — Isolated inter-process communication
  - **User (USER)** — Isolated UID/GID mappings (rootless containers)
  - **Cgroup** — Isolated cgroup view
- **Namespace Operations** — unshare, nsenter, clone
  - `unshare --pid --fork bash` — New PID namespace
  - `nsenter --target PID --pid --net` — Enter namespace
- **Container Building Blocks** — Namespaces (isolation) + cgroups (resource limits)
- **User Namespaces** — Map container root to unprivileged host user
- **Network Namespaces** — Full network stack isolation per container

## 6.5 PAM and Centralized Authentication (Deep Dive) [Part 65]

- **PAM Architecture** — Stacked modules for auth/account/password/session
- **PAM Modules (Deep)**
  - pam_unix — Standard Unix authentication
  - pam_sss / pam_ldap — Centralized auth
  - pam_mkhomedir — Auto-create home directories
  - pam_pwquality — Password complexity enforcement
  - pam_tally2 / pam_faillock — Account lockout after failures
  - pam_limits — Resource limits per user
  - pam_time — Time-based access restrictions
  - pam_access — Host-based access control
  - pam_wheel — Restrict su to wheel group
  - pam_mount — Auto-mount user volumes
- **NSS (Name Service Switch)** — Lookup order for passwd, group, shadow, hosts
  - /etc/nsswitch.conf — files, sss, ldap, compat
- **SSSD Deep Dive**
  - Domains, providers (id_provider, auth_provider, access_provider)
  - Caching behavior and offline login
  - Sudo rules from LDAP
  - HBAC (Host-Based Access Control)
- **Kerberos Deep Dive**
  - KDC, realms, tickets (TGT, service tickets)
  - kinit, klist, kvno, kdestroy
  - Keytab files (service authentication)
  - Clock synchronization requirement (5min skew)
- **realmd / adcli** — Domain join automation
- **Authselect** — PAM/NSS configuration framework (RHEL 8+)
  - `authselect select sssd with-mkhomedir`

## 6.6 System Hardening (Deep Dive) [Part 66]

- **CIS Benchmarks** — Center for Internet Security hardening standards
  - Level 1 (essential), Level 2 (defense in depth)
  - Automated scanning with OpenSCAP
- **auditd Deep Dive**
  - Audit rules: -w (watch file), -a (syscall audit)
  - ausearch, aureport, audit2allow
  - /var/log/audit/audit.log
  - Log forwarding to central syslog
- **sysctl Hardening**
  - net.ipv4.conf.all.accept_redirects = 0
  - net.ipv4.conf.all.accept_source_route = 0
  - net.ipv4.icmp_echo_ignore_broadcasts = 1
  - kernel.randomize_va_space = 2 (ASLR)
  - fs.protected_hardlinks = 1
  - fs.protected_symlinks = 1
- **Filesystem Hardening** — noexec, nosuid, nodev on partitions
  - /tmp, /var/tmp, /dev/shm with restricted options
- **SSH Hardening** — PermitRootLogin no, PasswordAuthentication no, Protocol 2
- **Boot Hardening** — GRUB password, Secure Boot
- **Service Minimization** — Disable unnecessary services (systemctl disable)
- **User Hardening** — Password policies, home directory permissions (750)
- **Network Hardening** — Disable unused network services, IP forwarding
- **Kernel Module Blacklisting** — Prevent loading unnecessary modules

## 6.7 I/O Models and Multiplexing

- **Blocking I/O** — Read/write blocks until data available or operation completes
  - Simple but one-thread-per-connection
  - Thread overhead for many connections
- **Non-Blocking I/O** — Returns immediately (EAGAIN/EWOULDBLOCK if not ready)
  - Application must poll repeatedly (busy-wait)
  - High CPU usage, impractical alone
- **I/O Multiplexing** — Single thread monitors multiple file descriptors
  - **select()** — Classic, oldest multiplexing API
    - Limited to FD_SETSIZE (typically 1024)
    - O(n) scan of all fds on every call
    - Modifies fd_set (must rebuild each iteration)
  - **poll()** — Improved, no hard fd limit
    - Uses pollfd array instead of bitmasks
    - Still O(n) scan
  - **epoll** — Linux-specific, scalable I/O multiplexing (Linux 2.6+)
    - `epoll_create()` — Create epoll instance
    - `epoll_ctl()` — Add/modify/remove monitored fds
    - `epoll_wait()` — Wait for events (returns only ready fds)
    - O(1) event notification (no scan)
    - Edge-triggered (ET) vs Level-triggered (LT) modes
    - LT (default): notified when fd is readable (like select/poll)
    - ET: notified only on state change (more efficient, requires non-blocking)
    - Used by: Nginx, Node.js, Redis, HAProxy
  - **kqueue** — BSD/macOS equivalent of epoll (not Linux, but conceptually similar)
- **io_uring** — Asynchronous I/O via ring buffers (Linux 5.1+)
  - Submission Queue (SQ) and Completion Queue (CQ) in shared memory
  - Submissions via ring buffer (no syscall overhead)
  - SQPoll mode: dedicated kernel thread polls SQ (truly zero-syscall)
  - Supports: read, write, open, close, stat, fsync, connect, accept, send, recv, fadvise, madvise, splice
  - Linked operations: chain I/O operations as a pipeline
  - Timeout support per-operation
  - Fixed files/buffers: pre-registered to avoid repeated registration
  - Used by: databases (RocksDB, ScyllaDB), web servers, NVMe drivers
  - `io_uring_setup()`, `io_uring_enter()`, `io_uring_register()` syscalls
- **AIO (POSIX AIO)** — User-space thread-based async I/O
  - `aio_read()`, `aio_write()`, `aio_error()`, `aio_return()`
  - Implemented as threads (not true kernel async)
  - Deprecated in favor of io_uring
- **Signal-Driven I/O** — Kernel signals application when fd is ready
  - `fcntl(fd, F_SETOWN, getpid())` — Set process for SIGIO
  - `fcntl(fd, F_SETFL, O_ASYNC)` — Enable signal-driven mode
  - Rarely used in practice (complex signal handling)
- **spliced I/O (sendfile/tee)** — Zero-copy data transfer
  - `sendfile()` — Transfer between file descriptors (kernel-space copy)
  - `splice()` — Move data through pipes without copying to userspace
  - `vmsplice()` — Splice userspace data to/from pipe
  - `copy_file_range()` — Zero-copy file copy (Linux 4.5+)
  - Used by web servers for file serving (Nginx sendfile on)

## 6.8 Hardware, Firmware, and Device Management

- **ACPI (Advanced Configuration and Power Interface)** — Hardware abstraction layer
  - Provides OS control over power management, thermal management, device configuration
  - ACPI tables: DSDT, SSDT, FADT, MADT, HPET, SRAT
  - Power states: G0 (working), G1 (sleeping), G2 (soft off), G3 (mechanical off)
  - Sleep states: S1 (CPU off), S2, S3 (suspend to RAM), S4 (suspend to disk)
  - Device states: D0 (fully on) through D3 (off)
  - C-states (CPU idle), P-states (CPU frequency scaling)
  - `acpitool`, `acpi_listen` — Query ACPI events
  - `/proc/acpi/` — ACPI information interface
- **udev** — Device manager for Linux (replaces devfs)
  - Manages /dev entries dynamically
  - Rules in `/etc/udev/rules.d/*.rules` and `/lib/udev/rules.d/`
  - udevadm info — Query device properties
  - udevadm monitor — Watch udev events in real-time
  - Persistent device naming: /dev/disk/by-id/, /dev/disk/by-uuid/, /dev/disk/by-path/
  - SUBSYSTEM, KERNEL, ATTR, ENV match rules
  - RUN, SYMLINK, NAME, MODE, GROUP, OWNER actions
  - systemd-udevd — Modern udev daemon (part of systemd)
- **Device Hotplug** — Add/remove hardware at runtime
  - USB hotplug: udev rules trigger on USB events
  - PCI hotplug: `echo 1 > /sys/bus/pci/rescan`
  - PCIe hotplug: surprise removal, graceful removal
  - SCSI hot-add/remove: `echo "- - -" > /sys/class/scsi_host/hostN/scan`
  - `udevadm trigger` — Re-trigger device events
- **sysfs (/sys)** — Exported kernel device/driver model
  - /sys/block/ — Block devices
  - /sys/class/ — Device classes (net, tty, disk, etc.)
  - /sys/bus/ — Bus types (pci, usb, scsi)
  - /sys/devices/ — Physical device tree
  - /sys/module/ — Loaded kernel modules
  - /sys/fs/ — Filesystem parameters
  - Per-device attributes: sys, stat, uevent, driver
- **/proc/sys/** — Tunable kernel parameters
  - `sysctl -a` — List all parameters
  - `sysctl -w net.ipv4.ip_forward=1` — Set at runtime
  - `/etc/sysctl.conf` or `/etc/sysctl.d/*.conf` — Persistent config
  - `sysctl -p` — Load from file
- **Kernel Device Model** — Unified device tree
  - bus_type, device, device_driver structures
  - Device tree (DT) for embedded systems (ARM)
  - Platform devices vs PCI devices vs USB devices
  - Device probes: driver binds to device via bus matching
- **dmidecode** — Read SMBIOS/DMI hardware info
  - `dmidecode -t memory` — Memory slots and specs
  - `dmidecode -t system` — System manufacturer, model, serial
- **lscpu / lsmem / lsblk / lspci / lsusb** — Hardware listing commands
  - `lscpu` — CPU topology, cores, threads, cache, NUMA
  - `lsmem` — Memory block sizes and online/offline status
  - `lsblk` — Block device tree with mountpoints
  - `lspci` — PCI device tree
  - `lsusb` — USB device tree
  - `lshw` — Comprehensive hardware listing
- **PCI Configuration Space** — 256 bytes per device (standard) or 4KB (PCIe extended)
  - Vendor ID, Device ID, Class Code, BAR registers
  - `setpci` — Read/write PCI configuration
- **IOMMU (I/O MMU)** — DMA remapping and isolation
  - Intel VT-d / AMD-Vi
  - Enables safe PCI passthrough (VFIO)
  - Device isolation, interrupt remapping, DMA protection
- **IRQ Handling** — Interrupt request management
  - `/proc/interrupts` — Per-CPU interrupt counts
  - IRQ affinity: `echo CPU_MASK > /proc/irq/IRQ_NUM/smp_affinity`
  - IRQ balancing daemon: `irqbalance` — Distribute IRQs across CPUs
- **Hardware Watchdog** — System reliability watchdog timer
  - `watchdog` daemon — Ping hardware watchdog to prevent reset
  - /dev/watchdog — Hardware watchdog device
  - Softdog — Software watchdog for testing
  - System reboots if watchdog not kicked within timeout
- **UEFI Variables** — Persistent firmware settings
  - `efivar -l` — List UEFI variables
  - `efivar -p VAR_NAME` — Print variable
  - Secure Boot keys stored as UEFI variables

## 6.9 cgroups Deep Dive

- **Control Groups (cgroups)** — Kernel mechanism for resource limiting/accounting/isolation
- **cgroups v1 (Legacy)**
  - Hierarchical, each controller in separate hierarchy
  - Mount: `mount -t cgroup -o cpu cgroup /sys/fs/cgroup/cpu`
  - Controllers: cpu, cpuacct, memory, blkio, devices, freezer, cpuset, pids, net_cls, net_prio
  - **cpu** — CFS bandwidth control, cpu.shares (weight), cpu.cfs_quota_us/period_us
  - **cpuacct** — CPU accounting, cpuacct.usage (nanoseconds)
  - **memory** — Memory limits, memsw (memory + swap), kmem (kernel memory)
    - memory.limit_in_bytes, memory.soft_limit_in_bytes
    - memory.usage_in_bytes, memory.max_usage_in_bytes
    - memory.oom_control, memory.swappiness
  - **blkio** — Block I/O throttling, weight-based proportional sharing
    - blkio.throttle.read_bps_device, blkio.weight
  - **devices** — Device access control (major:minor r/w)
    - devices.list, devices.allow, devices.deny
  - **freezer** — Suspend/resume processes (container freezing)
  - **cpuset** — Pin processes to specific CPUs and memory nodes
    - cpuset.cpus, cpuset.mems
  - **pids** — Limit number of processes in cgroup
  - **net_cls** — Classify network packets (with tc)
  - **net_prio** — Set priority of network traffic
- **cgroups v2 (Unified)**
  - Single hierarchy (unified), all controllers in one tree
  - Mount: `mount -t cgroup2 none /sys/fs/cgroup`
  - Enabled by default in modern distributions
  - All controllers: cpu, io, memory, pids, cpuset, hugetlb, perf_event, rdma, misc
  - **cpu.max** — Bandwidth (quota/period format replaces separate files)
  - **cpu.weight** — Proportional sharing (replaces cpu.shares, default 100)
  - **cpu.weight.nice** — Weight adjustment for nice values
  - **cpu.pressure** — PSI (Pressure Stall Information) for CPU
  - **memory.max** — Hard memory limit (replaces memory.limit_in_bytes)
  - **memory.high** — Throttle allocations above this (memory pressure)
  - **memory.low** — Best-effort memory protection
  - **memory.min** — Guaranteed memory protection
  - **memory.swap.max** — Swap limit
  - **memory.swap.current** — Current swap usage
  - **memory.oom.group** — OOM kill entire cgroup atomically
  - **io.max** — I/O bandwidth limits per device
  - **io.weight** — Proportional I/O sharing
  - **io.latency** — Target latency constraints
  - **io.pressure** — PSI for I/O
  - **memory.pressure** — PSI for memory
  - **psi** — Pressure Stall Information (some/full, avg10/avg60/avg300)
- **Container Integration**
  - Docker/Podman create cgroup per container
  - Kubernetes pod-level cgroups
  - `cat /proc/PID/cgroup` — Show cgroup membership
  - `systemd-cgls` — List cgroup tree
  - `systemd-cgtop` — Per-cgroup resource usage
- **Delegation** — Giving non-root users cgroup control
  - `machinectl` — systemd-nspawn container management
  - User namespace + cgroup delegation (rootless containers)
  - Delegation via systemd-run

## 6.10 System Calls Overview

- **System Call (syscall)** — Interface between user space and kernel space
  - Software interrupt (int 0x80 on x86, `syscall` instruction on x86-64)
  - User program requests kernel service, kernel executes and returns
- **System Call Categories**
  - **Process Control** — fork(), exec(), wait(), exit(), kill(), getpid(), setuid()
  - **File Management** — open(), read(), write(), close(), stat(), chmod(), chown(), link(), unlink(), rename(), truncate()
  - **Device Management** — ioctl(), mmap(), munmap(), read(), write() (device files)
  - **Information Maintenance** — getuid(), getgid(), time(), uname(), sysinfo()
  - **Communication** — pipe(), socket(), bind(), listen(), connect(), send(), recv(), shmget(), mmap()
  - **Protection** — chmod(), chown(), setuid(), setgid(), seccomp(), capset()
- **strace** — Trace system calls of a process
  - `strace -p PID` — Attach to running process
  - `strace -f -e trace=network command` — Follow forks, filter network calls
  - `strace -c` — Summary of syscall counts and times
  - `strace -o output.txt` — Write trace to file
  - `strace -t -T` — Timestamp and duration of each syscall
- **ltrace** — Trace library calls
  - `ltrace -p PID`, `ltrace -c command`
  - Shows shared library function calls (printf, malloc, etc.)
- **/usr/include/asm/unistd.h** — System call number definitions
  - x86-64: 0-450+ syscalls
  - `ausyscall` — List system calls with numbers
- **VDSO (Virtual Dynamic Shared Object)** — Kernel-provided shared library
  - Mapped into every process address space
  - Provides fast implementations of time-related syscalls (gettimeofday, clock_gettime)
  - Avoids syscall overhead for frequently called functions
  - `ldd /bin/ls` shows linux-vdso.so
- **ptrace** — Process tracing and debugging
  - Used by: strace, gdb, ltrace, seccomp-bpf
  - PTRACE_TRACEME, PTRACE_PEEKDATA, PTRACE_POKEDATA
  - Process can be stopped and inspected at each syscall
- **BPF (Berkeley Packet Filter)** — Originally for packet filtering
  - Extended to eBPF for general-purpose kernel programming
  - Seccomp-BPF: restrict system calls using BPF filters
  - Docker/Kubernetes seccomp profiles

## 6.11 Linux Security Modules (LSM) Deep Dive

- **LSM Framework** — Kernel hook architecture for MAC policies
  - Hooks inserted at every kernel access point (open, read, write, connect, etc.)
  - Only one LSM active per system (or stacking in newer kernels)
  - LSMs: SELinux, AppArmor, SMACK, TOMOYO, Yama, Landlock
- **SELinux (Security-Enhanced Linux)** — Type enforcement + role-based access control
  - **Contexts** — `user:role:type:level` (e.g., `system_u:system_r:httpd_t:s0`)
  - **Type Enforcement** — Rules define which types can access which types
  - **RBAC (Role-Based Access Control)** — Users assigned roles, roles define access
  - **MLS/MCS (Multi-Level/Multi-Category Security)** — Sensitivity levels and categories
    - MCS: containers use categories (s0:c123,c456)
    - MLS: classified information (Top Secret, Secret, Confidential)
  - **Booleans** — Runtime policy toggles
    - `getsebool -a` — List all booleans
    - `setsebool -P httpd_can_network_connect on` — Persistent
  - **Policy** — Compiled binary (policy.31 or similar)
    - Reference policy (refpolicy) — default on RHEL/Fedora
    - Custom modules via `semodule`
  - **Targeted Policy** — Default, restricts only targeted daemons
  - **MLS Policy** — Full military-grade MAC
  - **Troubleshooting** — `setroubleshoot`, `audit2why`, `audit2allow`
  - **SELinux in Containers** — MCS category separation, spc_t for privileged containers
- **AppArmor** — Path-based MAC (Ubuntu, SUSE, Debian)
  - **Profiles** — Per-program security rules
    - /etc/apparmor.d/ — Profile files
    - `aa-status` — Show active profiles
    - `aa-enforce` / `aa-complain` / `aa-disable`
    - `aa-genprof` — Generate profiles interactively
    - `aa-logprof` — Update profiles from logs
  - **Profiles types** — Deny-first (default), Allowlist
  - **Hat profiles** — Sub-profiles for SUID switching
  - **Network rules** — Network access control
  - **File rules** — Path-based file access
  - **DBus rules** — IPC access control
  - **Signal rules** — Process signal access
  - **Capability rules** — Linux capabilities control
- **SMACK (Simplified Mandatory Access Control Kernel)**
  — Simple label-based MAC (used in Tizen, some embedded systems)
  - **Labels** — String labels attached to processes and files
  - **Smack Labels** — Max 255 characters, assigned at boot or via xattr
  - **Access Rules** — `/etc/smack/accesses.d/`
    - Format: `subject_label object_label access_type`
    - Access types: r (read), w (write), x (execute), a (append), t (transmute)
  - **CIPSO/CALIPSO** — Network label translation for MAC labels over network
  - **Simplified model** — 5 permissions (read, write, append, execute, transmute)
  - `/sys/fs/smackfs/` — SMACK filesystem interface
- **TOMOYO** — Path-based MAC (simplest, Japan-origin)
  - **Profiles** — Numbered security profiles (0=disabled, 1=learning, 2=permissive, 3=enforcing)
  - **Domain policy** — Path-based access rules
  - `/etc/tomoyo/` — Configuration directory
  - `tomoyo-editpolicy` — Interactive policy editor
  - `tomoyo-setprofile` — Set profile for programs
  - **Path grouping** — Share policies between similar paths
  - Lowest overhead, simplest to configure
- **Yama LSM** — ptrace scope restriction
  - `/proc/sys/kernel/yama/ptrace_scope`
    - 0 (default): any process can ptrace
    - 1: only parent can ptrace
    - 2: only admin (CAP_SYS_PTRACE)
    - 3: no ptrace at all
- **Landlock LSM** — Unprivileged sandboxing (Linux 5.13+)
  - Per-process access control (no admin required)
  - Filesystem access restrictions
  - Network access restrictions (newer kernels)
  - `landlock_create_ruleset()`, `landlock_add_rule()`, `landlock_restrict_self()`
- **LSM Stacking** — Run multiple LSMs simultaneously (Linux 5.4+)
  - SELinux + Yama, AppArmor + Yama
  - Only one "major" MAC LSM + minor LSMs
- **seccomp-BPF** — System call filtering using BPF programs
  - `seccomp()` syscall — Set seccomp mode
  - BPF filter defines allowed/blocked syscalls
  - SECCOMP_RET_KILL, SECCOMP_RET_TRAP, SECCOMP_RET_ERRNO, SECCOMP_RET_ALLOW
  - Docker default seccomp profile: blocks ~44 dangerous syscalls
  - `prctl(PR_SET_NO_NEW_PRIVS)` — Required before seccomp
  - Tools: `strace -f -e seccomp`, `seccomp-tools` (Ruby)
- **Landlock vs SELinux vs AppArmor Comparison**
  - SELinux: Label-based, system-wide, complex, powerful (RHEL)
  - AppArmor: Path-based, per-program, simpler (Ubuntu)
  - Landlock: Unprivileged, per-process, sandbox-focused
  - SMACK: Label-based, minimal (embedded)
  - TOMOYO: Path-based, simplest, learning mode

## 6.12 Kernel Internals Deep Dive

- **Kernel Build from Source** — Compiling the Linux kernel
  - `make menuconfig` — Interactive kernel configuration (ncurses)
  - `make xconfig` — Graphical configuration (Qt)
  - `make oldconfig` — Update config for new kernel
  - `make -j$(nproc)` — Parallel compilation
  - `make modules_install` — Install modules to /lib/modules/
  - `make install` — Install kernel image
  - `make deb-pkg` / `make rpm-pkg` — Build distribution package
  - `arch/x86/configs/` — Default configs per architecture
- **Kconfig System** — Kernel configuration options
  - `=y` (built-in), `=m` (module), `# not set` (disabled)
  - Depends on, select, imply, default
  - `/proc/config.gz` — Running kernel config
  - `scripts/decode_configfile` — Decode config to human-readable
- **Kernel Command Line Deep Dive** — Boot parameters
  - `init=/bin/bash` — Boot to single shell
  - `root=/dev/mapper/vg-root` — Specify root device
  - `panic=10` — Reboot on kernel panic after 10 seconds
  - `mitigations=off` — Disable CPU vulnerability mitigations
  - `systemd.unit=multi-user.target` — Boot to specific target
  - `console=ttyS0,115200` — Serial console
  - `rd.break` / `break=` — Break into initramfs shell
  - `iommu=pt` — IOMMU passthrough mode
  - `/etc/default/grub` GRUB_CMDLINE_LINUX for persistence
- **printk and Dynamic Debug** — Kernel logging
  - `printk()` — Kernel space printf with log levels (0-7)
  - `pr_info()`, `pr_debug()`, `pr_err()` — Convenience macros
  - `/proc/dynamic_debug/control` — Runtime debug control
  - `echo 'file drivers/net/* +p' > /proc/dynamic_debug/control`
  - `dmesg -w` — Watch kernel messages live
  - `dmesg -T` — Human-readable timestamps
- **Kernel Threads (kthreads)** — Kernel execution contexts
  - Run in process context (can sleep, have own stacks)
  - `kthread_create()`, `kthread_run()`
  - `/proc/PID/status` shows kthreads (voluntary_ctxt_switches)
  - ksoftirqd, kswapd, kworker examples
- **Workqueues (cmwq)** — Deferred work in process context
  - `create_workqueue()`, `queue_work()`, `flush_work()`
  - Worker threads execute queued functions
  - Unbound vs bound workqueues
  - Used throughout kernel for deferred operations
- **RCU (Read-Copy-Update)** — Lock-free synchronization
  - Readers access data without locking
  - Writers create new copy, atomically swap pointer
  - Grace period: wait for all pre-existing readers to complete
  - `rcu_read_lock()` / `rcu_read_unlock()` — Reader-side
  - `synchronize_rcu()` — Wait for grace period
  - `call_rcu()` — Asynchronous grace period callback
  - Used for: routing tables, file descriptors, device lists
- **SRCU (Sleepable RCU)** — RCU variant allowing sleeping readers
  - `srcu_read_lock()` / `srcu_read_unlock()`
  - `synchronize_srcu()` — SRCU-specific grace period
- **Atomic Operations and Memory Barriers** — SMP correctness
  - `atomic_t`, `atomic_inc()`, `atomic_read()`
  - `smp_mb()` — Full memory barrier
  - `smp_rmb()` — Read memory barrier
  - `smp_wmb()` — Write memory barrier
  - `READ_ONCE()` / `WRITE_ONCE()` — Compiler barrier
- **Per-CPU Variables** — Lock-free per-CPU data
  - `DEFINE_PER_CPU(type, name)`
  - `get_cpu_var()`, `put_cpu_var()`
  - Avoids cache-line bouncing on SMP systems
  - Used for: counters, statistics, per-CPU caches
- **Lockdep** — Runtime lock dependency validator
  - Detects potential deadlocks before they happen
  - `/proc/lockdep_stats` — Lock dependency statistics
  - Lock ordering validation
  - CONFIG_LOCKDEP, CONFIG_PROVE_LOCKING
- **Futex (Fast Userspace Mutex)** — Userspace mutex implementation
  - `futex()` syscall — Fast path in userspace, slow path in kernel
  - Used by glibc pthread_mutex
  - `FUTEX_WAIT`, `FUTEX_WAKE`, `FUTEX_CMP_REQUEUE`
  - Priority inheritance for real-time processes
- **Seqlock** — Lock-free reader-biased synchronization
  - Sequence counter incremented on each write
  - Readers check sequence before and after read
  - Retry if sequence changed (writer was active)
  - Used for: time-of-day, rarely-written data
- **NUMA Deep Dive** — Non-Uniform Memory Access
  - **NUMA Distance Metrics** — `numactl --hardware` shows distances
  - **Zonelists** — Fallback zones for memory allocation
  - **NUMA balancing** — Automatic page migration (NUMA balancing)
    - PTE scanning for "accessed" bits
    - Pages migrated to node where accessed
    - `sysctl vm.numa_balancing`
  - **NUMA-aware allocation** — `mbind()`, `set_mempolicy()`
  - **numactl** — Pin processes to NUMA nodes
    - `numactl --cpunodebind=0 --membind=0 command`
    - `numactl --interleave=all command` — Round-robin across nodes
- **Huge Pages Deep Dive** — Large page support
  - **hugetlbfs** — Pre-allocated huge pages filesystem
    - `/sys/kernel/mm/hugepages/` — Huge page info
    - `vm.nr_hugepages` — Pre-allocate count
    - `mount -t hugetlbfs nodev /mnt/huge`
  - **Transparent HugePages (THP)** — Automatic large pages
    - `always`, `madvise`, `never` modes
    - `/sys/kernel/mm/transparent_hugepage/enabled`
    - Khugepaged background compaction
  - **Multi-Size THP (MTHP)** — Variable-size huge pages (Linux 6.8+)
    - 16K, 32K, 64K, 128K, 256K, 512K pages
    - Per-process control via madvise()
    - Better TLB coverage without 2MB commitment
  - **HugeTLB cgroup** — Huge page memory controller
- **DAMON (Data Access MONitor)** — Data access pattern monitoring
  - Monitors memory regions for access frequency
  - `/sys/kernel/mm/damon/` — DAMON sysfs interface
  - DAMOS (DAMON-based Operation Schemes) — Auto-tiering
  - Used for: memory tiering, proactive reclaim, profiling
- **MGLRU (Multi-Gen LRU)** — Modern page reclaim (Linux 6.1+)
  - Multiple generations instead of active/inactive lists
  - Better page aging for large memory workloads
  - `vm.vfs_cache_pressure`, LRU gen stats in /proc/vmstat
- **Folio Abstraction** — Unified page representation (Linux 5.16+)
  - Replaces compound pages and buffer_head
  - Cleaner API for page cache and memory management
  - `struct folio` — Base unit of page cache
- **Maple Tree** — VMA data structure (Linux 6.1+)
  - RCU-safe B-tree replacing red-black tree
  - Used for virtual memory area management
  - Better cache performance than rbtree
- **KASAN (Kernel Address Sanitizer)** — Memory error detection
  - Use-after-free, buffer overflow, use-after-scope
  - `kasan.fault=quarantine` for quarantine-based detection
  - CONFIG_KASAN=y
- **KFENCE (Kernel Electric-Fence)** — Low-overhead sampling detector
  - Sampling-based (production-safe)
  - Detects use-after-free, out-of-bounds
  - `kfence.sample_interval` — Sampling rate
- **userfaultfd** — Userspace page fault handling
  - Process handles its own page faults
  - Used for: live migration, snapshots, CRIU
  - `userfaultfd(2)` syscall,UFFDIO_COPY, UFFDIO_ZEROPAGE
- **sched_ext** — eBPF-programmable CPU scheduler (Linux 6.12+)
  - Custom scheduling policies via eBPF
  - BPF programs for scheduling decisions
  - scx_lavd, scx_rusty — Example schedulers
- **BPF Arenas** — Shared memory between eBPF and userspace
  - `bpf_arena_create()` — Create arena
  - Lock-free data sharing
  - Used for: eBPF map alternatives, large data structures

## 6.13 Modern System Calls

- **pidfd** — Process file descriptor
  - `pidfd_open()` — Get fd for process
  - Race-free signaling: `pidfd_send_signal()`
  - Pollable: `poll()` on pidfd waits for exit
  - Used by systemd for process management
- **openat2** — Extended open with resolution flags
  - `struct open_how` — flags, mode, resolve
  - `RESOLVE_BENEATH` — Don't escape parent directory
  - `RESOLVE_IN_ROOT` — Treat root as filesystem root
  - `RESOLVE_NO_MAGICLINKS` — Block symlink following
  - Security hardening, container rootfs access
- **statx** — Extended file metadata
  - Returns timestamps, mount ID, BTIME, creation time
  - `statx(AT_FDCWD, path, 0, STATX_*, &statxbuf)`
  - More info than stat() (stx_btime for birth time)
- **copy_file_range** — Zero-copy file copy
  - Kernel-space copy between file descriptors
  - No userspace buffer involved
  - `copy_file_range(fd_in, &off_in, fd_out, &off_out, len, 0)`
- **io_uring Multi-Shot** — Single SQE, multiple CQEs
  - One submission generates repeated completions
  - Used for: accept, recv, poll operations
  - `IOSQE_IO_DRAIN`, `IOSQE_IO_LINK` flags
- **io_uring Linked Requests** — Chained I/O operations
  - Link multiple SQEs for ordered execution
  - If one fails, subsequent are cancelled
  - Complex I/O pipelines without intermediate buffers
- **MADV_COLD / MADV_PAGEOUT** — Proactive page reclaim
  - `madvise(addr, len, MADV_COLD)` — Demote pages to inactive list
  - `madvise(addr, len, MADV_PAGEOUT)` — Force pages to swap
  - Used for: memory reclamation, tiering
- **pidfd_send_signal** — Signal via pidfd
  - `pidfd_send_signal(pidfd, sig, NULL, 0)`
  - Race-free alternative to kill()
- **mount_setattr** — Set mount attributes
  - `AT_RECURSIVE` for recursive attribute changes
  - MOUNT_ATTR_RDONLY, MOUNT_ATTR_NOSUID, MOUNT_ATTR_NODEV
- **landlock_create_ruleset** — Create Landlock ruleset
  - `landlock_create_ruleset(&attr, sizeof(attr), 0)`
  - Per-process filesystem sandboxing

## 6.14 Advanced Security Features

- **IMA (Integrity Measurement Architecture)** — File integrity measurement
  - Measures file hashes at access time
  - Policy rules: `/etc/ima/ima-policy`
  - `ima_policy=tcb` kernel parameter
  - IMA appraisal: verify against known-good hashes
  - `evmctl` — Extended Verification Module utility
- **EVM (Extended Verification Module)** — Security xattr protection
  - Cryptographic protection of security xattrs
  - Prevents tampering with SELinux labels, capabilities
  - HMAC or public-key based
- **Kernel Lockdown Mode** — Restrict kernel functionality
  - `lockdown=confidentiality` — Block /dev/mem, module loading
  - `lockdown=integrity` — Block code modification
  - LSM-based enforcement
  - Prevents root from modifying kernel at runtime
- **ASLR (Address Space Layout Randomization)** — Randomize memory layout
  - `kernel.randomize_va_space = 2` — Full randomization
  - Libraries, stack, heap, mmap, VDSO randomized
  - PIE (Position-Independent Executable) required for full benefit
- **Stack Protector** — Stack buffer overflow detection
  - `-fstack-protector-strong` — Canary-based protection
  - Canary value checked on function return
  - CONFIG_STACKPROTECTOR, CONFIG_STACKPROTECTOR_STRONG
- **PIE (Position-Independent Executable)** — ASLR-compatible binaries
  - Compiled with `-fPIE`, linked with `-pie`
  - All addresses relative to base, randomizable
- **Linux Capabilities Deep Dive** — Fine-grained root privileges
  - Decomposed root into ~41 distinct capabilities
  - `capsh --print` — Show current capabilities
  - `setcap cap_net_bind_service=+ep /path/to/binary`
  - **Capability bounding set** — Limits which caps can be acquired
    - `/proc/PID/status` CapBnd line
  - **File capabilities** — Per-executable capability set
    - CAP_NET_BIND_SERVICE, CAP_SYS_ADMIN, CAP_SYS_PTRACE
  - **Ambient capabilities** — Inherited across exec()
- **fscrypt** — Filesystem-level encryption
  - Per-file/directory encryption keys
  - ext4, f2fs, UBIFS support
  - `fscryptctl` — Key management utility
  - Policy: v1 (legacy), v2 (recommended)
  - Inline encryption on hardware (UFS, eMMC)
- **Integrity Policy Enforcement (IPE)** — Mandatory integrity
  - IMA successor (Linux 6.7+)
  - Kernel-enforced integrity verification
  - Policy-driven file access decisions
- **Sandboxing Overview** — Process isolation techniques
  - seccomp-BPF: syscall filtering
  - Landlock: unprivileged filesystem sandboxing
  - namespaces: resource isolation
  - chroot/pivot_root: filesystem isolation
  - AppArmor/SELinux: MAC policies

---

# Universal Concepts

## Cross-Cutting Principles

### Security Principles
- **Least Privilege** — Give minimum required access
- **Defense in Depth** — Multiple security layers
- **Separation of Duties** — No single person controls everything
- **Zero Trust** — Never trust, always verify
- **Principle of Fail-Safe Defaults** — Deny by default

### Operational Principles
- **Infrastructure as Code** — Everything reproducible from code
- **Immutable Infrastructure** — Replace, don't patch
- **Automation First** — Automate repetitive tasks
- **Monitoring Everything** — You can't fix what you can't see
- **Documentation** — Runbooks, architecture diagrams, postmortems
- **GitOps** — Git as single source of truth

### Networking Fundamentals
- **OSI Model** — Physical, Data Link, Network, Transport, Session, Presentation, Application
- **TCP/IP Model** — Link, Internet, Transport, Application
- **TCP vs UDP** — Reliable vs fast, connection-oriented vs connectionless
- **IP Addressing** — IPv4 (32-bit) vs IPv6 (128-bit), subnetting, CIDR notation
- **Subnetting** — Subnet masks, CIDR (/24, /16), usable hosts formula
- **DNS Resolution** — Recursive vs iterative queries
- **ARP (Address Resolution Protocol)** — MAC ↔ IP mapping
- **ICMP** — ping, traceroute
- **TCP Three-Way Handshake** — SYN → SYN-ACK → ACK
- **TCP States** — ESTABLISHED, TIME_WAIT, CLOSE_WAIT, LISTEN
- **TLS/SSL** — Transport Layer Security, certificate chain

### Storage Fundamentals
- **Block Storage** — Raw block devices (RAID, LVM)
- **File Storage** — Filesystem-based (NFS, CIFS)
- **Object Storage** — Key-value (S3, Swift)
- **Storage Stack** — Hardware → mdadm → LVM → Filesystem → Mount Point → Application
- **I/O Patterns** — Sequential vs Random, Read vs Write heavy
- **IOPS** — Input/Output Operations Per Second
- **Throughput** — Data transfer rate (MB/s)
- **Latency** — Time per operation (ms, μs)

### Linux Ecosystem
- **Certifications** — RHCSA, RHCE, LFCS, CKA, CompTIA Linux+
- **Major Distributions**
  - Server: RHEL, Rocky Linux, AlmaLinux, Ubuntu Server, Debian
  - Desktop: Ubuntu, Fedora, Linux Mint, openSUSE
  - Enterprise: SUSE Enterprise, RHEL
  - Container-optimized: Alpine, Flatcar, Bottlerocket
- **Community Resources** — kernel.org, LWN.net, Arch Wiki, Linux man pages
- **Open Source Licensing** — GPL, MIT, Apache, BSD, LGPL

### Troubleshooting Methodology
- **Identify** — What is the problem?
- **Gather Information** — Logs, metrics, symptoms
- **Form Hypothesis** — Likely cause
- **Test Hypothesis** — Narrow down systematically
- **Implement Fix** — Apply solution
- **Verify** — Confirm fix works
- **Document** — Record what happened and how it was fixed
- **Key Diagnostic Commands** — dmesg, journalctl, strace, lsof, ss, ip, top, free, df

### Performance Methodology
- **USE Method** — For each resource: Utilization, Saturation, Errors
- **RED Method** — For each service: Rate, Errors, Duration
- **60-Second Analysis** — Quick triage using vmstat, mpstat, iostat, free, top
- **Flame Graphs** — Visual CPU profiling
- **Latency Analysis** — Identifying slow operations

## Linux System Management Utilities

- **systemd-logind** — Session and seat management
  - User sessions, TTY allocation, seat management
  - `loginctl list-sessions`, `loginctl show-session`
  - Power management: `loginctl lock-sessions`, `loginctl suspend`
  - Lingering: `loginctl enable-linger user` — User services without login
  - `/var/run/user/UID/` — Per-user runtime directory
  - XDG_RUNTIME_DIR environment variable
- **Polkit (PolicyKit)** — Privilege escalation framework
  - Fine-grained authorization for non-root users
  - Actions defined in `/usr/share/polkit-1/actions/*.policy`
  - Rules in `/etc/polkit-1/rules.d/` and `/usr/share/polkit-1/rules.d/`
  - `pkaction --verbose` — Show action details
  - `pkcheck` — Check if action is authorized
  - `pkexec` — Execute program as another user (polkit agent)
  - JavaScript rules: `polkit.addRule(function(action, subject) { ... })`
  - Registered actions: org.freedesktop.login1.*, org.freedesktop.NetworkManager.*
- **systemd-resolved** — DNS stub resolver
  - Stub listener on 127.0.0.53
  - `/etc/resolv.conf → ../run/systemd/resolve/stub-resolv.conf`
  - `resolvectl status` — Show DNS configuration
  - `resolvectl query example.com` — DNS query
  - DNS-over-TLS, DNSSEC support
  - Per-link DNS configuration
- **systemd-networkd** — Network management daemon
  - `.network`, `.netdev`, `.link` unit files
  - DHCP, static, IPv6 SLAAC
  - `networkctl status`, `networkctl list`
  - Bond, bridge, VLAN, macvlan, vxlan support
  - Routing policy rules, DNS configuration
- **systemd-homed** — Portable home directories
  - LUKS-encrypted home directories
  - `homectl create`, `homectl activate`, `homectl deactivate`
  - SSH key-based remote access
- **systemd-machined** — Virtual machine/container management
  - `machinectl list`, `machinectl login`, `machinectl shell`
  - `systemd-nspawn` — Lightweight container/VM
  - Registration of LXC, QEMU/KVM, Docker containers
- **Flatpak** — Cross-distribution application packaging
  - Sandboxed applications with portals
  - Flathub repository
  - Runtime extensions
  - `flatpak install`, `flatpak run`, `flatpak update`
- **Snap** — Universal Linux packages (Canonical)
  - Sandboxed, auto-updating packages
  - Snap store, snap confinement (strict, classic, devmode)
  - `snap install`, `snap list`, `snap refresh`
  - snapd daemon
- **AppArmor vs SELinux Decision Guide**
  - Use AppArmor: Ubuntu, SUSE, embedded, simple needs
  - Use SELinux: RHEL/Fedora, fine-grained MAC, government compliance
  - Neither: minimal systems, containers with user namespaces

## Modern Filesystem Features

- **OverlayFS Advanced** — Multiple lower layers
  - Multiple read-only lower layers stacked
  - NFS export support (nfs_export=on)
  - xino (stable inode numbering across mounts)
  - metacopy (metadata-only copies)
  - Redirect_dir (redirect directory modifications)
  - `/proc/mounts` shows overlay mount options
- **F2FS Advanced** — Flash-optimized filesystem
  - Multi-head logging for parallel writes
  - GC pressure management
  - Compression support (lz4, zstd)
  - `f2fs.io` — F2FS debugging/info tool
  - `/sys/fs/f2fs/` — Per-device statistics
- **EROFS Advanced** — Compressed read-only filesystem
  - LZ4, LZMA, DEFLATE, ZSTD compression
  - Fixed-output mode for reproducible builds
  - Deduplication across images
  - `erofsfuse` — FUSE mount for non-kernel access
  - Used in: Android system images, container base images, firmware
- **bcachefs Advanced** — New CoW filesystem
  - RAID 0/1/5/6/10 support
  - Compression (zstd, lz4)
  - Encryption (chacha20, aes-xts)
  - Snapshots and quotas
  - Multi-device support
  - Online filesystem check
- **Filesystem Choice Guide**
  - ext4: Default, stable, good for most use cases
  - XFS: Large files, parallel I/O, databases
  - Btrfs: Snapshots, CoW, checksums (development, desktop)
  - ZFS: Enterprise, maximum data integrity
  - bcachefs: Modern all-in-one (emerging)
  - F2FS: Mobile/embedded flash storage
  - EROFS: Read-only container images, firmware
  - tmpfs: RAM-backed temporary storage
  - vfat: EFI System Partition, cross-platform
  - exfat: USB drives, SD cards

## Advanced Tracing One-Liners

- **perf stat** — Quick hardware counter overview
  - `perf stat -e cache-misses,instructions,cycles ./command`
  - `perf stat -p PID sleep 10` — Profile running process
- **perf record + flame graph** — CPU profiling
  - `perf record -g -p PID -- sleep 30`
  - `perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg`
- **bpftrace histograms** — Latency distribution
  - `bpftrace -e 'kprobe:vfs_read { @bytes = hist(arg2); }'`
  - `bpftrace -e 'tracepoint:syscalls:sys_exit_read /retval > 0/ { @ns = hist(args->ret); }'`
- **bpftrace counting** — Event frequency
  - `bpftrace -e 'tracepoint:syscalls:sys_enter_execve { @[comm] = count(); }'`
  - `bpftrace -e 'kprobe:tcp_connect { @[comm] = count(); }'`
- **ftrace function_graph** — Kernel call graph
  - `echo function_graph > /sys/kernel/debug/tracing/current_tracer`
  - `echo 1 > /sys/kernel/debug/tracing/tracing_on`
  - `cat /sys/kernel/debug/tracing/trace`
- **ftrace hist triggers** — In-kernel histograms
  - `echo 'hist:keys=comm:tsusecs' > /sys/kernel/debug/tracing/events/sched/sched_switch/trigger`
- **crash tool** — Kernel dump analysis
  - `crash /usr/lib/debug/lib/modules/$(uname -r)/vmlinux /var/crash/*/vmcore`
  - `bt` — Backtrace, `ps` — Process list, `log` — Kernel log
  - `vm` — Virtual memory, `files` — Open files

---

## Quick Reference: Key Files

| File | Purpose |
|------|---------|
| /etc/passwd | User accounts |
| /etc/shadow | Password hashes |
| /etc/group | Groups |
| /etc/fstab | Filesystem mount table |
| /etc/hosts | Static hostname resolution |
| /etc/resolv.conf | DNS configuration |
| /etc/nsswitch.conf | Name resolution order |
| /etc/ssh/sshd_config | SSH server configuration |
| /etc/sudoers | Sudo rules |
| /etc/systemd/system/ | Custom systemd units |
| /etc/logrotate.conf | Log rotation config |
| /etc/crontab | System cron jobs |
| /etc/sysctl.conf | Kernel parameters |
| /etc/security/limits.conf | Resource limits |
| /etc/pam.d/* | PAM configuration |
| /etc/apparmor.d/* | AppArmor profiles |
| /etc/audit/audit.rules | Audit rules |
| /proc/cpuinfo | CPU information |
| /proc/meminfo | Memory information |
| /proc/[pid]/* | Process information |
| /sys/* | Device/driver/kernel info |

## Quick Reference: Key Commands

| Category | Commands |
|----------|----------|
| Files | ls, cp, mv, rm, find, locate, ln, du, df |
| Text | cat, less, head, tail, grep, sed, awk, cut, sort |
| Users | useradd, usermod, userdel, passwd, id, groups, sudo |
| Processes | ps, top, htop, kill, nice, pgrep, pkill |
| Network | ip, ss, ping, traceroute, curl, wget, dig, nmap |
| Services | systemctl (start/stop/enable/status), journalctl |
| Packages | apt, dnf/yum, pacman, zypper |
| Storage | mount, fdisk, parted, pvcreate, vgcreate, lvcreate |
| Boot | grub2-mkconfig, dracut, systemctl, dmesg |
| Security | chmod, chown, getenforce, auditctl, firewall-cmd |

---

> **Total Concepts Cataloged: 1100+** across 6 levels + universal topics
>
> Sources: Course structure (67 parts), Linux kernel documentation (docs.kernel.org), Red Hat documentation, Ubuntu documentation, LinuxTeck, Medium, Coursera, FOSS Linux, computingforgeeks, various sysadmin guides and cheat sheets (2025-2026).
>
> Major additions: IPC mechanisms, Virtualization (KVM/QEMU/Xen/LXC), I/O models (epoll/io_uring), Hardware (ACPI/udev), cgroups v1/v2, System calls, LSM (SMACK/TOMOYO/Yama/Landlock), Tracing tools, Package building, Disaster recovery, Compliance, Advanced networking (BGP/OSPF/VRF/tc/MACsec/TUN-TAP), Advanced storage (iSCSI/NVMe-oF/dm-crypt/dm-verity/ZFS/Ceph/Btrfs/bcachefs), Advanced enterprise services (NFSv4/Samba AD DC/DRBD/GFS2/PXE), Container ecosystem (containerd/CRI-O/Podman/Buildah/Skopeo/cosign), Supply chain security (SBOM/Sigstore/SLSA/in-toto), Service mesh (Istio/Linkerd/Consul), Observability (Thanos/Cortex/Jaeger/Zipkin/Hubble/Tetragon), Kernel internals (RCU/workqueues/NUMA/HugePages/DAMON/MGLRU/KASAN), Modern syscalls (pidfd/openat2/statx/io_uring multi-shot), Security deep dives (IMA/EVM/kernel lockdown/ASLR/PIE/capabilities/fscrypt), systemd ecosystem (logind/homed/machined/resolved/networkd), Filesystem advanced (F2FS/EROFS/OverlayFS/bcachefs).
