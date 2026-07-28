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





[← Previous](16-section-13-tags-and-limits.md) | [↑ Index](index.md) | [Next →](18-level-3-advanced-practices-internals.md)
