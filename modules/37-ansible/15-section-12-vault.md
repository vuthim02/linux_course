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





[← Previous](14-section-11-handlers.md) | [↑ Index](index.md) | [Next →](16-section-13-tags-and-limits.md)
