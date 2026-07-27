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



---

[← Previous](15-section-12-vault.md) | [↑ Index](index.md) | [Next →](17-section-14-error-handling.md)
