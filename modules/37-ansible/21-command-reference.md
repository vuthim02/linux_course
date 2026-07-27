## 📖 Command Reference

### Level 1 — Basic

| Command | Description |
|---------|-------------|
| `ansible --version` | Show Ansible version and config file location |
| `ansible -m ping <host>` | Test SSH connectivity |
| `ansible -m command -a "cmd"` | Run command ad-hoc |
| `ansible -m shell -a "cmd"` | Run shell command (with pipes, etc.) |
| `ansible -m copy -a "src=... dest=..."` | Copy files ad-hoc |
| `ansible -m setup <host>` | Gather system facts |
| `ansible all -m setup -a "filter=..."` | Filter specific facts |
| `ansible-playbook playbook.yml` | Run a playbook |
| `ansible-playbook --check` | Dry run (no changes) |
| `ansible-playbook --diff` | Show file changes |
| `ansible-playbook --syntax-check` | Validate playbook syntax |

### Level 2 — Intermediary

| Command | Description |
|---------|-------------|
| `ansible-playbook --tags "tag1,tag2"` | Run only tagged tasks |
| `ansible-playbook --skip-tags "tag"` | Skip tagged tasks |
| `ansible-playbook --limit host1,host2` | Target specific hosts |
| `ansible-playbook --ask-vault-pass` | Prompt for vault password |
| `ansible-playbook -e "var=value"` | Pass extra variables |
| `ansible-playbook -i inventory.yml` | Use custom inventory |
| `ansible-vault create file.yml` | Create encrypted file |
| `ansible-vault edit file.yml` | Edit encrypted file |
| `ansible-vault encrypt file.yml` | Encrypt existing file |
| `ansible-vault decrypt file.yml` | Decrypt file |
| `ansible-vault view file.yml` | View encrypted file |
| `ansible-galaxy init role_name` | Create role skeleton |
| `ansible-galaxy install user.role` | Install role from Galaxy |
| `ansible-inventory --list` | Show parsed inventory |
| `ansible-inventory --graph` | Show inventory as graph |

### Level 2 — Intermediary (continued)

#### Key Modules Reference

| Module | Purpose |
|--------|---------|
| `ping` | Test connectivity |
| `command` | Run command (no shell features) |
| `shell` | Run command (with shell features) |
| `apt` | Manage apt packages |
| `yum` | Manage yum packages |
| `dnf` | Manage dnf packages |
| `package` | Cross-platform package manager |
| `service` | Manage system services |
| `systemd` | Manage systemd units |
| `copy` | Copy files to remote |
| `template` | Deploy Jinja2 templates |
| `file` | Manage files and directories |
| `user` | Manage user accounts |
| `group` | Manage groups |
| `lineinfile` | Ensure line in file |
| `replace` | Regex replace in file |
| `get_url` | Download files from URL |
| `unarchive` | Extract archives |
| `fetch` | Fetch files from remote to local |
| `git` | Manage git repos |
| `uri` | Interact with web services |
| `debug` | Print messages and variables |
| `set_fact` | Set custom facts |
| `fail` | Fail the task intentionally |
| `wait_for` | Wait for port/connection |
| `reboot` | Reboot managed host |
| `cron` | Manage cron jobs |
| `mount` | Mount filesystems |
| `selinux` | Manage SELinux settings |
| `ufw` | Manage UFW firewall |

---



---

[← Previous](20-deep-understanding.md) | [↑ Index](index.md) | [Next →](22-whats-coming-in-part-38.md)
