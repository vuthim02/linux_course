# 🐧 Linux System Administrator — Complete Course
## Part 37 of ∞: Automation with Ansible

---

> **Reverse Engineering Approach:** Instead of memorizing YAML syntax, we start from *what problem Ansible solves* (managing 100 servers without SSHing into each one), then decompose how it works under the hood (SSH, Python, push model, idempotency).

---

![Ansible architecture — control node, inventory, modules, and managed nodes](https://docs.ansible.com/projects/sdk/en/latest/_images/sdk-local-executor.svg)

*Ansible SDK local execution flow — control node pushes to managed hosts via SSH (Ansible project / Apache 2.0)*

## 🎯 What You Will Achieve

This module is structured across three progressive levels:

| Level | Focus | What You'll Learn |
|-------|-------|-------------------|
| ⭐ Level 1: Basic — Foundations | Ansible Basics | What is Ansible, installation, inventory, ad-hoc commands, playbooks |
| ⭐ Level 2: Intermediary — Daily Administration | Modules, Variables, Roles & Advanced Topics | Modules deep dive, variables & facts, Jinja2 templates, conditionals & loops, roles, handlers, vault, tags, error handling |
| ⭐ Level 3: Advanced — Practices & Internals | Practices, Internals & Reference | Hands-On Practices, deep understanding (async, fact caching), command reference, self-test |

---

## ⭐ Level 1: Basic — Foundations

![Ansible control node to managed nodes](https://docs.ansible.com/projects/sdk/en/latest/_images/sdk-local-executor.svg)

> *"Automation is not about replacing humans — it's about freeing them from repetitive tasks so they can solve harder problems."*

---

## 🔍 Section 1: What Is Ansible?

### The Problem Ansible Solves

Imagine you have 50 servers:
- Install Nginx on all of them
- Ensure the `nginx.conf` is identical
- Restart the service if config changes
- Create user `deploy` with a specific SSH key on every server

Without automation: SSH into each one, type the same commands 50 times, pray you didn't miss one. With Ansible: one command, all 50 servers converge to the exact same state.

### Key Concepts

| Concept | Meaning |
|---------|---------|
| **Agentless** | No software installed on managed nodes — Ansible uses SSH only |
| **Push-based** | Control node pushes config to managed nodes (vs pull-based like Puppet) |
| **SSH** | Transport protocol — Ansible connects over SSH (default) |
| **YAML** | Playbooks and inventory are written in YAML Ain't Markup Language |
| **Idempotency** | Running the same playbook multiple times produces the same result — it won't break anything if already applied |
| **Inventory** | List of hosts Ansible manages |
| **Modules** | Reusable units of work (install package, copy file, start service) |
| **Playbooks** | YAML files that define automation workflows |

### How Ansible Works Internally (Reverse Engineering)

```
┌─────────────────────┐         SSH          ┌─────────────────────┐
│   Control Node      │ ──────────────────→  │   Managed Node 1    │
│   (where you run    │                      │   (target server)   │
│    ansible-playbook)│                      │                     │
│                     │                      │  /tmp/ansible-tmp/  │
│  1. Read playbook   │                      │  ┌───────────────┐  │
│  2. Gather facts?   │                      │  │ ansible_mod.py│  │
│  3. Push Python     │                      │  │ (module code) │  │
│     module to /tmp/ │                      │  └───────────────┘  │
│  4. Execute module  │                      │                     │
│  5. Collect results │                      │  Python executes    │
│  6. Remove module   │                      │  module, writes     │
│                     │                      │  result to stdout   │
└─────────────────────┘                      └─────────────────────┘
```

**Step by step:**
1. Ansible reads the inventory and playbook on the control node
2. Opens an SSH connection to each managed host
3. Copies the Python module code (generated from the YAML task) to `/tmp/ansible-tmp-*` on the target
4. Executes the module via SSH with JSON arguments
5. The module runs, checks current state vs desired state, makes changes if needed
6. Results (JSON) are written to stdout, Ansible collects and displays them
7. Module files are cleaned up — no persistent agent remains

### Idempotency Design

Every Ansible module is built with idempotency in mind:

```python
# Pseudocode of how a module thinks:
def ensure_package_installed(name="nginx", state="present"):
    if package_is_installed(name):
        return {"changed": False, "msg": "already installed"}
    else:
        install_package(name)
        return {"changed": True, "msg": "package installed"}
```

Running it once installs Nginx. Running it again does nothing — the state already matches.

---

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

## ⚡ Section 4: Ad-hoc Commands

Ad-hoc commands run a single module against hosts without a playbook.

### Ping Module — Test Connectivity

```bash
ansible all -m ping
```

```json
web1.example.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

### Command Module — Run Any Command

```bash
ansible all -m command -a "uptime"
ansible all -m command -a "df -h"
ansible webservers -m command -a "free -m"
```

### Shell Module — Command with Shell Features

```bash
ansible all -m shell -a "echo $HOSTNAME && whoami"
ansible all -m shell -a "ps aux | grep nginx | wc -l"
```

### Copy Module — Copy Files to Remote

```bash
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts_backup mode=0644"
```

### Setup Module — Gather Facts

```bash
ansible localhost -m setup
ansible webservers -m setup -a "filter=ansible_os_family"
ansible all -m setup -a "filter=ansible_default_ipv4"
```

```json
"ansible_default_ipv4": {
    "address": "192.168.1.100",
    "broadcast": "192.168.1.255",
    "gateway": "192.168.1.1",
    "interface": "eth0",
    "macaddress": "aa:bb:cc:dd:ee:ff",
    "netmask": "255.255.255.0",
    "network": "192.168.1.0",
    "type": "ether"
}
```

---

## 📜 Section 5: Playbooks

A **playbook** is a YAML file containing one or more plays. Each play targets a group of hosts and runs a list of tasks.

### Structure

```yaml
---
- name: Configure Web Servers
  hosts: webservers
  become: yes
  vars:
    http_port: 80
    max_clients: 200

  tasks:
    - name: Install Nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    - name: Deploy configuration
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Restart Nginx

    - name: Start and enable Nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: yes

  handlers:
    - name: Restart Nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
```

### Running a Playbook

```bash
ansible-playbook site.yml
ansible-playbook site.yml -i inventory.yml
ansible-playbook site.yml --check  # dry run
ansible-playbook site.yml --diff   # show changes
```

### Anatomy of a Task

```yaml
- name: Descriptive name of what this task does
  ansible.builtin.module_name:
    param1: value1
    param2: value2
  register: result_var          # save output to variable
  when: condition               # conditional execution
  notify: handler_name          # trigger handler if changed
  ignore_errors: yes            # don't fail if error
  tags:                         # tag for selective execution
    - install
    - nginx
```

### Facts (ansible_facts)

Facts are system information gathered from managed hosts automatically.

```yaml
- name: Show OS family fact
  ansible.builtin.debug:
    msg: "OS family is {{ ansible_facts['os_family'] }}"

- name: Install package based on OS
  ansible.builtin.package:
    name: httpd
    state: present
  when: ansible_facts['os_family'] == "RedHat"
```

---

## ⭐ Level 2: Intermediary — Daily Administration

![Ansible modules](https://docs.ansible.com/ansible/latest/_images/ansible_automatic_diagram.png)

> *"Modules are the verbs of Ansible. Master them, and you can describe any server state in YAML."*

---

## 🧩 Section 6: Modules Deep Dive

### Package Module

```yaml
- name: Install package (cross-platform)
  ansible.builtin.package:
    name: nginx
    state: present  # present | absent | latest

- name: Install with apt
  ansible.builtin.apt:
    name: "{{ packages }}"
    state: present
    update_cache: yes

- name: Install with yum
  ansible.builtin.yum:
    name: httpd
    state: latest
```

### Service Module

```yaml
- name: Start and enable service
  ansible.builtin.service:
    name: nginx
    state: started     # started | stopped | restarted | reloaded
    enabled: yes       # start on boot
```

### Copy Module

```yaml
- name: Copy file with permissions
  ansible.builtin.copy:
    src: /local/file.txt
    dest: /remote/file.txt
    owner: root
    group: root
    mode: '0644'
    backup: yes       # backup existing file before overwriting
```

### Template Module

```yaml
- name: Deploy templated config
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
```

### File Module

```yaml
- name: Create directory
  ansible.builtin.file:
    path: /var/www/myapp
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'

- name: Create symlink
  ansible.builtin.file:
    src: /opt/app/current
    dest: /var/www/myapp
    state: link

- name: Create empty file
  ansible.builtin.file:
    path: /etc/myapp/config
    state: touch
    mode: '0644'
```

### User Module

```yaml
- name: Create user with SSH key
  ansible.builtin.user:
    name: deploy
    shell: /bin/bash
    groups: sudo
    append: yes
    state: present

- name: Set authorized SSH key
  ansible.posix.authorized_key:
    user: deploy
    state: present
    key: "{{ lookup('file', '/home/admin/.ssh/deploy_key.pub') }}"
```

### Lineinfile Module

```yaml
- name: Ensure line exists in file
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PermitRootLogin'
    line: 'PermitRootLogin no'
    backup: yes

- name: Ensure line is absent
  ansible.builtin.lineinfile:
    path: /etc/hosts
    line: '192.168.1.100 old-server'
    state: absent
```

### Systemd Module

```yaml
- name: Reload systemd daemon
  ansible.builtin.systemd:
    daemon_reload: yes

- name: Start custom service
  ansible.builtin.systemd:
    name: myapp
    state: started
    enabled: yes
    daemon_reload: yes
```

### Get URL Module

```yaml
- name: Download file from URL
  ansible.builtin.get_url:
    url: https://releases.ubuntu.com/22.04/ubuntu-22.04-desktop.iso
    dest: /tmp/ubuntu.iso
    checksum: sha256:abc123...
    mode: '0644'
```

### Unarchive Module

```yaml
- name: Extract archive
  ansible.builtin.unarchive:
    src: /tmp/app.tar.gz
    dest: /opt/app
    remote_src: yes    # source is already on remote
    owner: www-data
    group: www-data
```

### Fetch Module

```yaml
- name: Fetch file from remote to local
  ansible.builtin.fetch:
    src: /var/log/syslog
    dest: /backups/logs/{{ inventory_hostname }}/syslog
    flat: no
```

---

## 🔢 Section 7: Variables and Facts

### Defining Variables

```yaml
# In playbook
vars:
  app_port: 3000
  app_name: myapp
  users:
    - alice
    - bob

# In vars file
# vars/main.yml
db_host: postgres.example.com
db_port: 5432
```

```yaml
# Using vars_files in a playbook
- hosts: all
  vars_files:
    - vars/main.yml
    - "vars/{{ ansible_facts['os_family'] }}.yml"
```

### Fact Gathering

```yaml
- hosts: all
  gather_facts: yes       # default: yes

- hosts: all
  gather_facts: no        # skip for speed
```

### set_fact — Create Custom Facts

```yaml
- name: Set custom fact
  ansible.builtin.set_fact:
    nginx_version: "1.24.0"
    app_url: "http://{{ ansible_facts['default_ipv4']['address'] }}:{{ app_port }}"
```

### register — Capture Task Output

```yaml
- name: Check if Nginx is running
  ansible.builtin.command: systemctl is-active nginx
  register: nginx_status
  ignore_errors: yes

- name: Debug output
  ansible.builtin.debug:
    var: nginx_status.stdout

- name: Use registered variable
  ansible.builtin.debug:
    msg: "Nginx is {{ 'active' if nginx_status.rc == 0 else 'inactive' }}"
```

### debug — Print Values

```yaml
- name: Print variable
  ansible.builtin.debug:
    msg: "The port is {{ app_port }}"

- name: Print all facts
  ansible.builtin.debug:
    var: ansible_facts
```

### Variable Precedence (lowest to highest)

1. Role defaults (`roles/role/defaults/main.yml`)
2. Inventory vars (`inventory.yml` or `group_vars/all`)
3. Inventory group vars (`group_vars/group_name`)
4. Inventory host vars (`host_vars/host_name`)
5. Playbook `vars`
6. Playbook `vars_files`
7. `vars_prompt`
8. `set_fact` / `register`
9. `--extra-vars` (highest)

> **Rule of thumb:** `--extra-vars` always wins. Role defaults are the easiest to override.

---

## 🎨 Section 8: Templates with Jinja2

Jinja2 is Python's templating engine. Ansible uses it for `.j2` template files.

### Template File Example

```nginx
# nginx.conf.j2
worker_processes {{ ansible_facts['processor_cores'] }};

events {
    worker_connections {{ nginx_worker_connections | default(1024) }};
}

http {
    server {
        listen {{ http_port }};
        server_name {{ server_name }};

        location / {
            proxy_pass http://127.0.0.1:{{ app_port }};
        }

        {% if enable_ssl %}
        listen 443 ssl;
        ssl_certificate /etc/ssl/certs/{{ ssl_cert }};
        ssl_certificate_key /etc/ssl/private/{{ ssl_key }};
        {% endif %}
    }
}
```

### Using Templates in Playbooks

```yaml
- name: Deploy Nginx template
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Reload Nginx
```

### Filters in Templates

```yaml
{{ variable | default('fallback') }}       # Default value
{{ list | unique }}                        # Remove duplicates
{{ list | join(', ') }}                    # Join list to string
{{ string | upper }}                       # Uppercase
{{ string | lower }}                       # Lowercase
{{ dict | to_json }}                       # Convert to JSON
{{ dict | to_yaml }}                       # Convert to YAML
{{ path | basename }}                      # Extract filename
{{ path | dirname }}                       # Extract directory
{{ ip | ipaddr('network') }}               # IP address filter
{{ 'hello' | regex_replace('^h', 'H') }}   # Regex replace
```

### Conditionals in Templates

```jinja2
{% if ansible_facts['os_family'] == 'Debian' %}
APT::Install-Recommends "0";
{% elif ansible_facts['os_family'] == 'RedHat' %}
installonly_limit = 3
{% endif %}
```

### Loops in Templates

```jinja2
# List all upstream servers
upstream backend {
{% for server in backend_servers %}
    server {{ server }}:{{ backend_port }};
{% endfor %}
}
```

---

## 🔄 Section 9: Conditionals and Loops

### When — Conditional Execution

```yaml
- name: Install Apache on Debian
  ansible.builtin.apt:
    name: apache2
    state: present
  when: ansible_facts['os_family'] == "Debian"

- name: Install Apache on RedHat
  ansible.builtin.yum:
    name: httpd
    state: present
  when: ansible_facts['os_family'] == "RedHat"

- name: Reboot only if kernel was updated
  ansible.builtin.reboot:
  when: kernel_update.changed
```

### Complex Conditions

```yaml
- name: Stop service if not production
  ansible.builtin.service:
    name: myapp
    state: stopped
  when:
    - ansible_facts['os_family'] == "Debian"
    - app_env != "production"
    - inventory_hostname not in groups['dbservers']

- name: Debug with and/or
  ansible.builtin.debug:
    msg: "Run only on Monday"
  when:
    - (ansible_facts['os_family'] == "Debian") or (ansible_facts['os_family'] == "RedHat")
    - ansible_date_time.weekday == "Monday"
```

### Loop — Iterate Over Items

```yaml
- name: Install multiple packages
  ansible.builtin.apt:
    name: "{{ item }}"
    state: present
  loop:
    - git
    - curl
    - htop
    - vim

- name: Create multiple users
  ansible.builtin.user:
    name: "{{ item.name }}"
    shell: "{{ item.shell | default('/bin/bash') }}"
    groups: "{{ item.groups | default('') }}"
  loop:
    - { name: alice, shell: /bin/zsh }
    - { name: bob, groups: sudo }
    - { name: charlie }
```

### with_dict — Loop Over Dictionary

```yaml
- name: Configure users from dictionary
  ansible.builtin.user:
    name: "{{ item.key }}"
    uid: "{{ item.value.uid }}"
    groups: "{{ item.value.groups }}"
  with_dict:
    alice:
      uid: 1001
      groups: sudo
    bob:
      uid: 1002
      groups: www-data
```

### loop_control

```yaml
- name: Install packages with progress
  ansible.builtin.package:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - postgresql
    - redis
  loop_control:
    pause: 2           # wait 2 seconds between each
    label: "{{ item }}" # display friendly name
    index_var: idx      # access loop index
```

---

## 🏗️ Section 10: Roles

Roles organize playbooks into reusable components. They follow a standard directory structure.

### Directory Structure

```
roles/
└── nginx/
    ├── tasks/
    │   └── main.yml          # Main list of tasks
    ├── handlers/
    │   └── main.yml          # Handlers
    ├── templates/
    │   └── nginx.conf.j2     # Jinja2 templates
    ├── files/
    │   └── default.conf      # Static files for copy
    ├── vars/
    │   └── main.yml          # High-priority variables
    ├── defaults/
    │   └── main.yml          # Low-priority (default) variables
    └── meta/
        └── main.yml          # Role dependencies and metadata
```

### Creating a Role

```bash
ansible-galaxy init nginx
ansible-galaxy init --init-path roles/ nginx
```

### Role Tasks Example

```yaml
# roles/nginx/tasks/main.yml
---
- name: Install Nginx
  ansible.builtin.package:
    name: nginx
    state: present

- name: Deploy configuration
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Reload Nginx

- name: Start Nginx
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: yes
```

### Role Defaults vs Vars

```yaml
# roles/nginx/defaults/main.yml
---
nginx_port: 80
nginx_user: www-data
worker_processes: 4
```

```yaml
# roles/nginx/vars/main.yml
---
# Overrides defaults — hard to override from playbook
nginx_conf_path: /etc/nginx/nginx.conf
```

### Using Roles in Playbooks

```yaml
---
- hosts: webservers
  become: yes
  roles:
    - common
    - nginx
    - role: postgresql
      vars:
        pg_port: 5433       # override role default

# Alternative syntax with options
- hosts: dbservers
  roles:
    - role: postgresql
      tags: db
      when: ansible_facts['os_family'] == "Debian"
```

### Role Dependencies

```yaml
# roles/wordpress/meta/main.yml
---
dependencies:
  - role: nginx
    vars:
      nginx_port: 8080
  - role: php-fpm
    vars:
      php_version: "8.1"
  - role: mariadb
```

### ansible-galaxy — Community Roles

```bash
# Search for roles
ansible-galaxy search nginx

# Install a role
ansible-galaxy install geerlingguy.nginx

# Install from requirements file
ansible-galaxy install -r requirements.yml
```

```yaml
# requirements.yml
---
roles:
  - name: geerlingguy.nginx
    version: 3.1.4
  - name: geerlingguy.postgresql
    version: 3.5.0
```

---

## 🔔 Section 11: Handlers

Handlers are tasks that only run when notified by another task. They run once, at the end of the play, regardless of how many times they were notified.

### Pattern: Template → Restart Service

```yaml
tasks:
  - name: Deploy Nginx config
    ansible.builtin.template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify:
      - Test Nginx config
      - Reload Nginx

  - name: Update site content
    ansible.builtin.copy:
      src: index.html
      dest: /var/www/html/index.html
    notify: Reload Nginx

handlers:
  - name: Test Nginx config
    ansible.builtin.command: nginx -t
    listen: reload nginx

  - name: Reload Nginx
    ansible.builtin.service:
      name: nginx
      state: reloaded
    listen: reload nginx
```

### Handler Ordering

```yaml
handlers:
  - name: Restart Postgresql
    ansible.builtin.service:
      name: postgresql
      state: restarted
    listen: "restart database"

  - name: Restart App
    ansible.builtin.service:
      name: myapp
      state: restarted
    listen: "restart app"
```

### Handler with Listen

```yaml
# Multiple tasks can notify the same handler topic
# Handlers listen for a topic name
tasks:
  - name: Update config
    template: ...
    notify: restart web

  - name: Update SSL cert
    copy: ...
    notify: restart web

handlers:
  - name: Restart Nginx
    service:
      name: nginx
      state: restarted
    listen: "restart web"
```

---

## 🔐 Section 12: Vault

Ansible Vault encrypts sensitive data (passwords, API keys, SSH keys) so they can be stored in version control safely.

### Creating an Encrypted File

```bash
ansible-vault create secrets.yml
# Opens $EDITOR, type content, save
```

```yaml
# secrets.yml (encrypted)
db_password: SuperSecret123
api_key: sk-abc123def456
```

### Editing an Encrypted File

```bash
ansible-vault edit secrets.yml
```

### Encrypting/Decrypting Existing Files

```bash
ansible-vault encrypt group_vars/all/vault.yml
ansible-vault decrypt secrets.yml
ansible-vault view secrets.yml    # view without decrypting file
```

### Using Vault in Playbooks

```yaml
# Include vaulted vars
- hosts: all
  vars_files:
    - secrets.yml
```

```bash
ansible-playbook site.yml --ask-vault-pass
ansible-playbook site.yml --vault-password-file ~/.vault_pass
```

### Vault IDs (Multiple Passwords)

```bash
# Create vault with specific ID
ansible-vault create --vault-id prod@~/.vault-pass-prod prod_secrets.yml
ansible-vault create --vault-id dev@~/.vault-pass-dev dev_secrets.yml
```

```bash
# Run with multiple vault IDs
ansible-playbook site.yml --vault-id prod@~/.vault-pass-prod --vault-id dev@~/.vault-pass-dev
```

### Referencing Vaulted Variables

```yaml
# In playbook, use vaulted variables just like normal vars
- name: Configure DB
  ansible.builtin.template:
    src: db_config.j2
    dest: /etc/myapp/db_config.yml
  vars:
    db_password: "{{ vault_db_password }}"
```

---

## 🏷️ Section 13: Tags and Limits

### Tags — Run Specific Tasks

```yaml
- name: Install Nginx
  ansible.builtin.apt:
    name: nginx
    state: present
  tags:
    - nginx
    - install

- name: Configure Nginx
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  tags:
    - nginx
    - configure
```

### Using Tags

```bash
# Run only tasks tagged "nginx"
ansible-playbook site.yml --tags nginx

# Run tasks tagged "install" or "configure"
ansible-playbook site.yml --tags "install,configure"

# Skip tasks with "configure" tag
ansible-playbook site.yml --skip-tags configure

# Tag assignment at play level
ansible-playbook site.yml --tags "always"
```

### Tag Special Keywords

```yaml
- name: Always run this task (even with --tags)
  ansible.builtin.debug:
    msg: "Always runs"
  tags: always

- name: Never run this task with --tags
  ansible.builtin.debug:
    msg: "Only without tags specified"
  tags: never
```

### Limit — Target Specific Hosts

```bash
# Run against specific host
ansible-playbook site.yml --limit web1.example.com

# Run against multiple hosts
ansible-playbook site.yml --limit web1.example.com,db1.example.com

# Run against a group subset
ansible-playbook site.yml --limit webservers

# Exclude a host
ansible-playbook site.yml --limit 'all:!web1.example.com'
```

---

## 🚨 Section 14: Error Handling

### ignore_errors — Continue on Failure

```yaml
- name: Check if service exists
  ansible.builtin.command: systemctl status myapp
  register: service_check
  ignore_errors: yes

- name: Start service if it exists
  ansible.builtin.service:
    name: myapp
    state: started
  when: service_check.rc == 0
```

### failed_when — Custom Failure Conditions

```yaml
- name: Run script
  ansible.builtin.shell: /opt/deploy.sh
  register: script_result
  failed_when:
    - script_result.rc != 0
    - '"ERROR" in script_result.stderr'
    - script_result.stdout is not search("Deploy complete")
```

### changed_when — Custom Change Detection

```yaml
- name: Run database migration
  ansible.builtin.shell: /opt/migrate.sh
  register: migration
  changed_when: '"Migration applied" in migration.stdout'
  failed_when:
    - migration.rc != 0
    - '"FATAL" in migration.stderr'
```

### Block/Rescue/Always — Try/Catch for Ansible

```yaml
- name: Deploy application with error handling
  block:
    - name: Pull latest code
      ansible.builtin.git:
        repo: https://github.com/myorg/myapp.git
        dest: /opt/myapp
        version: main

    - name: Install dependencies
      ansible.builtin.command: npm install
      args:
        chdir: /opt/myapp

    - name: Start application
      ansible.builtin.systemd:
        name: myapp
        state: restarted

  rescue:
    - name: Rollback to previous version
      ansible.builtin.git:
        repo: https://github.com/myorg/myapp.git
        dest: /opt/myapp
        version: previous-stable

    - name: Notify failure
      ansible.builtin.shell: echo "Deploy failed, rolled back" | mail -s "Deploy" admin@example.com

  always:
    - name: Cleanup temp files
      ansible.builtin.file:
        path: /tmp/deploy-{{ ansible_date_time.epoch }}
        state: absent
```

---

## ⭐ Level 3: Advanced — Practices & Internals

![Advanced Ansible automation](https://docs.ansible.com/ansible/latest/_images/ansible_automatic_diagram.png)

> *"Practice transforms knowledge into instinct. These exercises build production-ready Ansible skills."*

---

## 🛠️ Section 15: Hands-On Practices

### Level 1 — Basic

#### Practice 1: Write an Inventory

Create `/etc/ansible/hosts`:

```ini
[webservers]
web1 ansible_host=192.168.1.10 ansible_user=root
web2 ansible_host=192.168.1.11 ansible_user=root

[dbservers]
db1 ansible_host=192.168.1.20 ansible_user=root

[all:vars]
ansible_ssh_private_key_file=/home/admin/.ssh/id_rsa
```

Test:

```bash
ansible all -m ping -i /etc/ansible/hosts
```

#### Practice 2: Ping All Hosts

```bash
ansible all -m ping -o
```

Expected output:

```
web1 | SUCCESS => {"changed": false, "ping": "pong"}
web2 | SUCCESS => {"changed": false, "ping": "pong"}
db1  | SUCCESS => {"changed": false, "ping": "pong"}
```

#### Practice 3: Ad-hoc Commands

```bash
# Check disk usage on all servers
ansible all -m command -a "df -h /"

# Check memory
ansible all -m shell -a "free -h | grep Mem"

# Copy /etc/hosts to all servers
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts_backup"

# Gather OS facts
ansible all -m setup -a "filter=ansible_os_family"
```

#### Practice 4: First Playbook — Install Nginx

```yaml
# install-nginx.yml
---
- name: Install and configure Nginx
  hosts: webservers
  become: yes
  tasks:
    - name: Update apt cache
      ansible.builtin.apt:
        update_cache: yes
        cache_valid_time: 3600

    - name: Install Nginx
      ansible.builtin.apt:
        name: nginx
        state: present

    - name: Start and enable Nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: yes

    - name: Deploy index.html
      ansible.builtin.copy:
        content: "<h1>Managed by Ansible</h1>"
        dest: /var/www/html/index.html
```

```bash
ansible-playbook install-nginx.yml
```

### Level 2 — Intermediary

#### Practice 5: Create a User with SSH Key

```yaml
# create-user.yml
---
- name: Create deploy user with SSH access
  hosts: all
  become: yes
  vars:
    deploy_user: deploy
    ssh_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."

  tasks:
    - name: Create deploy user
      ansible.builtin.user:
        name: "{{ deploy_user }}"
        shell: /bin/bash
        groups: sudo
        append: yes
        create_home: yes

    - name: Set authorized key
      ansible.posix.authorized_key:
        user: "{{ deploy_user }}"
        state: present
        key: "{{ ssh_key }}"

    - name: Allow sudo without password
      ansible.builtin.lineinfile:
        path: /etc/sudoers
        line: "{{ deploy_user }} ALL=(ALL) NOPASSWD: ALL"
        validate: 'visudo -cf %s'
```

#### Practice 6: Manage Config File with Template

```jinja2
# nginx.conf.j2
server {
    listen {{ http_port }};
    server_name {{ server_name }};

    root {{ doc_root }};

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://localhost:{{ app_port }};
        proxy_set_header Host $host;
    }
}
```

```yaml
# template-demo.yml
---
- name: Deploy templated Nginx config
  hosts: webservers
  become: yes
  vars:
    http_port: 8080
    server_name: "{{ ansible_facts['hostname'] }}"
    doc_root: /var/www/myapp
    app_port: 3000

  tasks:
    - name: Ensure doc root exists
      ansible.builtin.file:
        path: "{{ doc_root }}"
        state: directory
        mode: '0755'

    - name: Deploy template
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/sites-available/myapp
      notify: Reload Nginx

    - name: Enable site
      ansible.builtin.file:
        src: /etc/nginx/sites-available/myapp
        dest: /etc/nginx/sites-enabled/myapp
        state: link

  handlers:
    - name: Reload Nginx
      ansible.builtin.service:
        name: nginx
        state: reloaded
```

#### Practice 7: Build a LAMP Stack Role

```bash
ansible-galaxy init --init-path roles/ lamp
```

```yaml
# roles/lamp/tasks/main.yml
---
- name: Install Apache
  ansible.builtin.package:
    name: "{{ apache_package }}"
    state: present

- name: Start Apache
  ansible.builtin.service:
    name: "{{ apache_service }}"
    state: started
    enabled: yes

- name: Install MariaDB
  ansible.builtin.package:
    name: mariadb-server
    state: present

- name: Install PHP
  ansible.builtin.package:
    name: "{{ php_packages }}"
    state: present

- name: Deploy PHP info page
  ansible.builtin.copy:
    content: "<?php phpinfo(); ?>"
    dest: "{{ doc_root }}/info.php"
```

```yaml
# roles/lamp/defaults/main.yml
---
apache_package: apache2
apache_service: apache2
doc_root: /var/www/html
php_packages:
  - php
  - php-mysql
  - libapache2-mod-php
```

```yaml
# roles/lamp/vars/main.yml
---
# Override for RHEL
apache_package: httpd
apache_service: httpd
```

```yaml
# site.yml
---
- hosts: all
  roles:
    - lamp
```

#### Practice 8: Use Vault for Secrets

```bash
ansible-vault create group_vars/all/vault.yml
```

```yaml
# Enter password: myvaultpass
# Content:
vault_db_password: MyS3cretP@ss
vault_api_key: sk-live-abc123
```

```yaml
# playbook.yml
---
- hosts: all
  vars_files:
    - group_vars/all/vault.yml
  tasks:
    - name: Show secret (for demo only — never do this in production)
      ansible.builtin.debug:
        msg: "DB password is {{ vault_db_password }}"
      no_log: true
```

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

#### Practice 9: Run Playbook with Tags

```yaml
# tagged-playbook.yml
---
- hosts: all
  become: yes
  tasks:
    - name: Install Nginx
      ansible.builtin.apt:
        name: nginx
        state: present
      tags: install

    - name: Configure Nginx
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      tags: configure

    - name: Restart Nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
      tags: restart

    - name: Verify Nginx
      ansible.builtin.uri:
        url: http://localhost
        status_code: 200
      tags: verify
```

```bash
# Only install
ansible-playbook tagged-playbook.yml --tags install

# Install and configure
ansible-playbook tagged-playbook.yml --tags "install,configure"

# Skip restart and verify
ansible-playbook tagged-playbook.yml --skip-tags "restart,verify"
```

#### Practice 10: Error Handling with Block/Rescue

```yaml
# error-handling.yml
---
- hosts: all
  become: yes
  tasks:
    - name: Deploy with error handling
      block:
        - name: Pull code
          ansible.builtin.git:
            repo: https://github.com/example/myapp.git
            dest: /opt/myapp
            version: main

        - name: Build application
          ansible.builtin.shell: |
            cd /opt/myapp
            ./build.sh

        - name: Deploy to production
          ansible.builtin.copy:
            src: /opt/myapp/build/
            dest: /var/www/myapp/
            remote_src: yes

      rescue:
        - name: Rollback
          ansible.builtin.shell: /opt/rollback.sh
          register: rollback_result

        - name: Send alert
          ansible.builtin.shell: |
            curl -X POST https://alerts.example.com/deploy \
              -H "Content-Type: application/json" \
              -d '{"status":"failed","host":"{{ inventory_hostname }}"}'

      always:
        - name: Cleanup build artifacts
          ansible.builtin.file:
            path: /opt/myapp/build
            state: absent
```

#### Practice 11: Orchestrate with Facts

```yaml
# facts-demo.yml
---
- hosts: all
  tasks:
    - name: Show distribution info
      ansible.builtin.debug:
        msg: >
          Host {{ ansible_facts['hostname'] }}
          runs {{ ansible_facts['distribution'] }}
          {{ ansible_facts['distribution_version'] }}
          on {{ ansible_facts['architecture'] }}

    - name: Show memory info
      ansible.builtin.debug:
        msg: "Total RAM: {{ ansible_facts['memtotal_mb'] }} MB | Free: {{ ansible_facts['memfree_mb'] }} MB"

    - name: Create host-specific config
      ansible.builtin.template:
        src: host_config.j2
        dest: "/etc/myapp/config-{{ ansible_facts['hostname'] }}.yml"
      vars:
        cpu_cores: "{{ ansible_facts['processor_cores'] }}"
        ip_address: "{{ ansible_facts['default_ipv4']['address'] }}"
```

#### Practice 12: Dynamic Inventory with Script

```bash
#!/usr/bin/env python3
# inventory_script.py
import json

inventory = {
    "webservers": {
        "hosts": ["web1", "web2"],
        "vars": {
            "ansible_user": "admin"
        }
    },
    "dbservers": {
        "hosts": ["db1"]
    },
    "_meta": {
        "hostvars": {
            "web1": {"ansible_host": "10.0.0.1"},
            "web2": {"ansible_host": "10.0.0.2"},
            "db1": {"ansible_host": "10.0.0.3"}
        }
    }
}

print(json.dumps(inventory, indent=2))
```

```bash
chmod +x inventory_script.py
ansible all -i inventory_script.py -m ping
```

#### Practice 13: Asynchronous Tasks

```yaml
# async-demo.yml
---
- hosts: all
  tasks:
    - name: Run long task asynchronously
      ansible.builtin.shell: /opt/long_running_task.sh
      async: 3600        # max time in seconds
      poll: 0            # fire and forget

    - name: Check on async task
      ansible.builtin.async_status:
        jid: "{{ async_result.ansible_job_id }}"
      register: job_result
      until: job_result.finished
      retries: 30
      delay: 10
```

#### Practice 14: Use Connection Plugins

```yaml
---
- name: Manage local machine
  hosts: localhost
  connection: local
  tasks:
    - name: Create directory locally
      ansible.builtin.file:
        path: /tmp/ansible-local-test
        state: directory

- name: Manage Docker container
  hosts: docker_containers
  connection: docker
  tasks:
    - name: Install package in container
      ansible.builtin.apt:
        name: curl
        state: present
```

### Level 3 — Advanced

#### Practice 15: Real-World Integration — Complete Server Provisioning

```yaml
# provision-server.yml
---
- name: Bootstrap — Install Python (for minimal systems)
  hosts: all
  gather_facts: no
  become: yes
  vars:
    ansible_python_interpreter: /usr/bin/python3
  tasks:
    - name: Install Python 3
      ansible.builtin.raw: test -e /usr/bin/python3 || (apt -y update && apt -y install python3)
      changed_when: false

    - name: Install dependencies
      ansible.builtin.raw: apt -y install python3-apt
      changed_when: false

- name: Base — Common configuration for all servers
  hosts: all
  become: yes
  gather_facts: yes
  vars_files:
    - group_vars/all/vault.yml
  tasks:
    - name: Set hostname
      ansible.builtin.hostname:
        name: "{{ inventory_hostname }}"

    - name: Update /etc/hosts
      ansible.builtin.lineinfile:
        path: /etc/hosts
        line: "{{ ansible_facts['default_ipv4']['address'] }} {{ inventory_hostname }}"
        state: present

    - name: Create admin user
      ansible.builtin.user:
        name: admin
        shell: /bin/bash
        groups: sudo
        append: yes
        password: "{{ vault_admin_password | password_hash('sha512') }}"

    - name: Deploy SSH key
      ansible.posix.authorized_key:
        user: admin
        state: present
        key: "{{ lookup('file', 'files/admin_rsa.pub') }}"

    - name: Configure SSH hardening
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "{{ item.regexp }}"
        line: "{{ item.line }}"
      loop:
        - { regexp: '^PermitRootLogin', line: 'PermitRootLogin no' }
        - { regexp: '^PasswordAuthentication', line: 'PasswordAuthentication no' }
        - { regexp: '^PubkeyAuthentication', line: 'PubkeyAuthentication yes' }
        - { regexp: '^Port', line: 'Port 2222' }
      notify: Restart SSH

    - name: Install common packages
      ansible.builtin.apt:
        name:
          - ufw
          - fail2ban
          - htop
          - ntp
          - curl
          - git
          - unattended-upgrades
        state: present
        update_cache: yes

    - name: Configure firewall
      community.general.ufw:
        rule: "{{ item.rule }}"
        port: "{{ item.port }}"
        proto: tcp
      loop:
        - { rule: allow, port: '2222' }
        - { rule: allow, port: '80' }
        - { rule: allow, port: '443' }

    - name: Enable firewall
      community.general.ufw:
        state: enabled

    - name: Configure automatic security updates
      ansible.builtin.template:
        src: 50unattended-upgrades.j2
        dest: /etc/apt/apt.conf.d/50unattended-upgrades

  handlers:
    - name: Restart SSH
      ansible.builtin.service:
        name: sshd
        state: restarted

- name: Web — Configure web servers
  hosts: webservers
  become: yes
  roles:
    - nginx
    - role: app-deploy
      vars:
        app_version: "{{ lookup('env', 'APP_VERSION') | default('latest', true) }}"
    - role: monitoring-agent

- name: DB — Configure database servers
  hosts: dbservers
  become: yes
  roles:
    - postgresql
    - role: backup-agent
      vars:
        backup_bucket: "{{ vault_backup_bucket }}"
        backup_key: "{{ vault_backup_key }}"
```

```bash
# Usage
ansible-playbook provision-server.yml -i production.yml --ask-vault-pass --limit webservers --tags "base,nginx"
```

---

## 🧠 Deep Understanding

### How Ansible Works Internally

#### SSH Connection Flow

```
1.  Control Node opens SSH connection to Managed Node
2.  Creates temporary directory: /tmp/ansible-tmp-<random>/
3.  Writes module arguments as JSON to temp dir
4.  Transfers module Python file to temp dir
5.  Executes module via SSH:
       /usr/bin/python3 /tmp/ansible-tmp-*/AnsiballZ_module.py
6.  Module runs, connects to system APIs (apt, systemd, etc.)
7.  Module outputs JSON result to stdout
8.  Control Node captures stdout, closes SSH connection
9.  Control Node cleans up temp directory
10. Displays result to user
```

#### Idempotency Design

Each module follows a **state-check → state-change** pattern:

```
┌─────────────┐
│  Read       │  ← Query current state (is package installed?)
│  Current    │
│  State      │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Compare    │  ← Does current match desired?
│  with       │     (state: present, port: 80, etc.)
│  Desired    │
└──────┬──────┘
       │
       ├── Match ──→ Return {"changed": false}
       │
       └── No match ──→ Apply change ──→ Return {"changed": true}
```

#### Fact Caching

By default, facts are gathered at the start of every playbook run. For large environments, enable fact caching:

```ini
# ansible.cfg
[defaults]
gathering = smart
fact_caching = redis
fact_caching_timeout = 86400
fact_caching_connection = localhost:6379:0
```

```bash
# Or use JSON file caching
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
```

#### Async and Polling

For long-running tasks (30+ seconds), use async mode:

```yaml
- name: Long running task
  ansible.builtin.shell: /opt/long_task.sh
  async: 7200           # max runtime: 2 hours
  poll: 30              # check every 30 seconds (0 = fire and forget)

- name: Fire and forget
  ansible.builtin.shell: /opt/background_job.sh
  async: 3600
  poll: 0               # don't wait for completion
```

Retrieve results later:

```yaml
- name: Check async job
  ansible.builtin.async_status:
    jid: "{{ background_result.ansible_job_id }}"
  register: job_status
  until: job_status.finished
  retries: 60
  delay: 10
```

#### Connection Plugins

| Plugin | Use Case | Example |
|--------|----------|---------|
| `local` | Run on control node | `connection: local` |
| `ssh` | Default SSH connection | `ansible_user=admin` |
| `docker` | Manage Docker containers | `connection: docker` |
| `winrm` | Manage Windows hosts | `ansible_connection: winrm` |
| `podman` | Manage Podman containers | `connection: podman` |

### Architecture Summary

```
┌─────────────────────────────────────────────────────────┐
│                    CONTROL NODE                          │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │ Inventory │  │ Playbook │  │ ansible-playbook CLI │  │
│  └─────┬────┘  └────┬─────┘  └──────────┬───────────┘  │
│        │            │                   │              │
│        ▼            ▼                   ▼              │
│  ┌───────────────────────────────────────────────┐     │
│  │           Ansible Engine (Python)              │     │
│  │  • Parse inventory                             │     │
│  │  • Compile playbook into tasks                 │     │
│  │  • Resolve variables / facts                   │     │
│  │  • Determine task order & dependencies         │     │
│  └────────────────────┬──────────────────────────┘     │
│                       │                                │
│                       ▼                                │
│  ┌───────────────────────────────────────────────┐     │
│  │           SSH / Connection Layer               │     │
│  │  • Open connection                            │     │
│  │  • Push module + arguments                    │     │
│  │  • Execute Python module                      │     │
│  │  • Collect JSON result                        │     │
│  │  • Close connection                           │     │
│  └───────────────────────────────────────────────┘     │
└────────────────────────────────────────────────────────┘
```

---

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

## 👀 What's Coming in Part 38

**Part 38: Container Basics — Docker and Podman**

- What containers are and why they matter
- Docker architecture (daemon, client, registry, images, containers)
- Installing Docker and Podman
- `docker run`, `docker ps`, `docker images`, `docker exec`, `docker logs`
- Building images with Dockerfiles
- Docker Compose for multi-container apps
- Podman as a daemonless alternative
- Container networking and volumes
- Hands-on: Dockerize a LAMP stack
- Self-test: 15 questions to validate readiness

---

## 📝 Self-Test

Answer these 15 questions to verify you understand Part 37.

**1.** What does "agentless" mean in the context of Ansible?

**2.** Explain the push-based architecture of Ansible.

**3.** What is idempotency and why is it important in configuration management?

**4.** Write a one-line Ansible command to check disk space on all servers in the `webservers` group.

**5.** What is the difference between the `command` and `shell` modules?

**6.** How does Ansible execute a module on a remote host internally? Describe the steps.

**7.** What is the purpose of `register` in a playbook?

**8.** Write a YAML playbook snippet that installs Nginx only on Debian-based systems.

**9.** What are handlers and when do they run?

**10.** How do you encrypt sensitive data in Ansible and use it in a playbook?

**11.** What is the difference between `vars` and `defaults` in a role?

**12.** What does `ansible-playbook site.yml --tags install --limit web1` do?

**13.** Write a Jinja2 template snippet that loops through a list of backend servers and generates upstream blocks.

**14.** How does `block/rescue/always` work for error handling?

**15.** Describe the variable precedence order from lowest to highest.

### Answer Key

**1.** Agentless means Ansible does not require any software installed on managed nodes — it uses SSH only.

**2.** The control node pushes configuration to managed nodes (the control node initiates SSH connections and executes modules).

**3.** Idempotency means running the same playbook multiple times produces the same result. It ensures safe re-runs and prevents unintended changes.

**4.** `ansible webservers -m shell -a "df -h"`

**5.** `command` runs commands without shell features (no pipes, redirects, variables). `shell` runs through `/bin/sh` and supports shell features.

**6.** ① Open SSH connection ② Create temp directory ③ Write module Python file ④ Write JSON args ⑤ Execute module via SSH ⑥ Module checks/does work ⑦ Module outputs JSON result ⑧ Collect and display result ⑨ Clean up temp files.

**7.** `register` saves a task's output (stdout, stderr, rc, etc.) into a variable for use in later tasks.

**8.**
```yaml
- name: Install Nginx on Debian
  ansible.builtin.apt:
    name: nginx
    state: present
  when: ansible_facts['os_family'] == "Debian"
```

**9.** Handlers are tasks that run only when notified by another task. They run once at the end of the play, regardless of how many times notified.

**10.** Use `ansible-vault create secrets.yml` to encrypt data, reference vaulted variables like normal vars, and run playbooks with `--ask-vault-pass`.

**11.** `defaults` have the lowest precedence and are meant to be overridden. `vars` have higher precedence and override `defaults`.

**12.** It runs the playbook `site.yml` executing only tasks tagged `install` targeting only host `web1`.

**13.**
```jinja2
upstream backend {
{% for server in backend_servers %}
    server {{ server }};
{% endfor %}
}
```

**14.** `block` contains the main tasks. If any task in `block` fails, execution moves to `rescue` (like catch). `always` runs regardless of success or failure (like finally).

**15.** Role defaults → inventory vars → group vars → host vars → playbook vars → vars_files → vars_prompt → set_fact/register → extra_vars (highest).

**Score:** 12/15 correct = ready for Part 38.

---

*Previous → Part 36: Advanced Shell Scripting*
*Next → Part 38: Container Basics — Docker and Podman*

[← Previous](part36.md) | [Next →](part38.md)
