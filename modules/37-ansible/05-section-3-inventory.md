## 📋 Section 3: Inventory

An **inventory** is the list of hosts Ansible manages. Default location: `/etc/ansible/hosts`.

### INI Format

```ini
# /etc/ansible/hosts
web1.example.com
web2.example.com
db.example.com

[webservers]
web1.example.com
web2.example.com

[dbservers]
db.example.com

[all:vars]
ansible_user=admin
ansible_ssh_private_key_file=/home/admin/.ssh/id_rsa
```

### YAML Format

```yaml
# inventory.yml
all:
  hosts:
    web1.example.com:
    web2.example.com:
    db.example.com:
  children:
    webservers:
      hosts:
        web1.example.com:
        web2.example.com:
    dbservers:
      hosts:
        db.example.com:
  vars:
    ansible_user: admin
    ansible_ssh_private_key_file: /home/admin/.ssh/id_rsa
```

### Group Vars and Host Vars

```bash
mkdir -p group_vars host_vars
```

```yaml
# group_vars/webservers.yml
nginx_port: 8080
app_env: production

# group_vars/all.yml
ntp_server: pool.ntp.org
dns_server: 8.8.8.8
```

```yaml
# host_vars/web1.example.com
ansible_host: 192.168.1.10
custom_var: special_value
```

### Patterns

```bash
# All hosts
ansible all -m ping

# Specific group
ansible webservers -m ping

# Wildcard
ansible '*.example.com' -m ping

# Exclusion (!)
ansible 'webservers:!web1.example.com' -m ping

# Intersection (&)
ansible 'webservers:&dbservers' -m ping

# Multiple groups
ansible 'webservers:dbservers' -m ping
```

---



---

[← Previous](04-section-2-installation.md) | [↑ Index](index.md) | [Next →](06-section-4-ad-hoc-commands.md)
