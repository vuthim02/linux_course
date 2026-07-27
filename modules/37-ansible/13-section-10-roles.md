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



---

[← Previous](12-section-9-conditionals-and-loops.md) | [↑ Index](index.md) | [Next →](14-section-11-handlers.md)
