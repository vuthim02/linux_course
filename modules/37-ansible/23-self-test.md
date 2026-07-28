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


*Previous → Part 36: Advanced Shell Scripting*
*Next → Part 38: Container Basics — Docker and Podman*

[← Previous](part36.md) | [Next →](part38.md)



[← Previous](22-whats-coming-in-part-38.md) | [↑ Index](index.md)
