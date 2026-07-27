## 🔧 Section 2: Installation

### Install via APT (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install ansible -y
ansible --version
```

### Install via PIP (any OS — latest version)

```bash
python3 -m pip install --user ansible
~/.local/bin/ansible --version
```

### Install via DNF (RHEL/CentOS/Fedora)

```bash
sudo dnf install epel-release -y
sudo dnf install ansible -y
ansible --version
```

### Verify Installation

```bash
$ ansible --version
ansible [core 2.16.3]
  config file = /etc/ansible/ansible.cfg
  configured module search path = ['/home/user/.ansible/plugins/modules']
  ansible python module location = /usr/lib/python3/dist-packages/ansible
  ansible collection location = /home/user/.ansible/collections
  executable location = /usr/bin/ansible
  python version = 3.12.3
```

### Configuration File Locations (priority order)

1. `ANSIBLE_CONFIG` environment variable
2. `./ansible.cfg` (current directory)
3. `~/.ansible.cfg` (home directory)
4. `/etc/ansible/ansible.cfg`

```ini
# /etc/ansible/ansible.cfg
[defaults]
inventory = /etc/ansible/hosts
host_key_checking = False
forks = 20
gathering = implicit
timeout = 30
log_path = /var/log/ansible.log
```

---



---

[← Previous](03-section-1-what-is-ansible.md) | [↑ Index](index.md) | [Next →](05-section-3-inventory.md)
