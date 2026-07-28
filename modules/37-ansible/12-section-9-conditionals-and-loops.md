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





[← Previous](11-section-8-templates-with-jinja2.md) | [↑ Index](index.md) | [Next →](13-section-10-roles.md)
