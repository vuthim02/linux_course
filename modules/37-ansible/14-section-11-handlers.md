## 🔔 Section 11: Handlers

Handlers are tasks that only run when notified by another task. They run once, at the end of the play, regardless of how many times they were notified.

### Pattern: Template → Restart Service

```yaml
tasks:
  - name: Deploy Nginx config
    ansible.builtin.template:
      src: nginx.conf.j2
      dest: /etc/nginx/nginx.conf
    notify:
      - Test Nginx config
      - Reload Nginx

  - name: Update site content
    ansible.builtin.copy:
      src: index.html
      dest: /var/www/html/index.html
    notify: Reload Nginx

handlers:
  - name: Test Nginx config
    ansible.builtin.command: nginx -t
    listen: reload nginx

  - name: Reload Nginx
    ansible.builtin.service:
      name: nginx
      state: reloaded
    listen: reload nginx
```

### Handler Ordering

```yaml
handlers:
  - name: Restart Postgresql
    ansible.builtin.service:
      name: postgresql
      state: restarted
    listen: "restart database"

  - name: Restart App
    ansible.builtin.service:
      name: myapp
      state: restarted
    listen: "restart app"
```

### Handler with Listen

```yaml
# Multiple tasks can notify the same handler topic
# Handlers listen for a topic name
tasks:
  - name: Update config
    template: ...
    notify: restart web

  - name: Update SSL cert
    copy: ...
    notify: restart web

handlers:
  - name: Restart Nginx
    service:
      name: nginx
      state: restarted
    listen: "restart web"
```





[← Previous](13-section-10-roles.md) | [↑ Index](index.md) | [Next →](15-section-12-vault.md)
