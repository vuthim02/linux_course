## 11.5 Ansible — Agentless Automation

Ansible is an agentless, push-based configuration management tool by Red Hat.

### Architecture

- **Control node**: runs `ansible-playbook`; connects via SSH
- **Managed nodes**: no agent required; Python must be present
- **Inventory**: list of hosts (INI/YAML)
- **Modules**: discrete units of work (package, service, copy, template)
- **Playbooks**: YAML files describing desired state

```bash
# Inventory file (hosts.ini)
[webservers]
web1 ansible_host=10.0.0.1
web2 ansible_host=10.0.0.2

[dbservers]
db1 ansible_host=10.0.0.10
```

```yaml
# playbook.yml
- name: Configure web server
  hosts: webservers
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Start nginx
      service:
        name: nginx
        state: started
        enabled: yes
    - name: Deploy config
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: restart nginx
  handlers:
    - name: restart nginx
      service:
        name: nginx
        state: restarted
```

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Idempotency** | Modules check current state before making changes |
| **Facts** | System information gathered via `setup` module |
| **Variables** | `{{ variable }}` in templates; `vars:` in playbooks |
| **Tags** | Run subsets: `ansible-playbook --tags "nginx"` |
| **Roles** | Reusable collections of tasks, templates, and variables |
| **Vault** | Encrypt sensitive data: `ansible-vault encrypt secrets.yml` |

### Commands

```bash
ansible all -i hosts.ini -m ping           # Test connectivity
ansible-playbook -i hosts.ini playbook.yml  # Run playbook
ansible-playbook --check playbook.yml       # Dry run
ansible-playbook --syntax-check playbook.yml
ansible-vault encrypt group_vars/all/vault.yml
ansible-galaxy init my_role                 # Scaffold a role
```

### Ansible vs Puppet vs Salt vs Chef

| Aspect | Ansible | Puppet | Salt | Chef |
|--------|---------|--------|------|------|
| Agent | No (SSH) | Yes | Yes (optional) | Yes |
| Push/Pull | Push | Pull | Both | Pull |
| Language | YAML | Puppet DSL | YAML + Jinja | Ruby DSL |
| Learning curve | Low | Medium | Medium | High |
| Best for | Ad-hoc, cloud | Large infra | High-scale | Full-stack devs |
