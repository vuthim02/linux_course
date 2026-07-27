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



---

[← Previous](06-section-4-ad-hoc-commands.md) | [↑ Index](index.md) | [Next →](08-level-2-intermediary-daily-administration.md)
