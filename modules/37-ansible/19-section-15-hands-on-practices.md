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
# Override for RHEL
apache_package: httpd
apache_service: httpd
```

```yaml
# site.yml
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





[← Previous](18-level-3-advanced-practices-internals.md) | [↑ Index](index.md) | [Next →](20-deep-understanding.md)
