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





[← Previous](09-section-6-modules-deep-dive.md) | [↑ Index](index.md) | [Next →](11-section-8-templates-with-jinja2.md)
