## 7. SaltStack States

### SLS Format

**`/srv/salt/nginx/init.sls`**:
```yaml
nginx-package:
  pkg.installed:
    - name: nginx
    - refresh: true

nginx-config:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://nginx/files/nginx.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - require:
      - pkg: nginx-package

nginx-service:
  service.running:
    - name: nginx
    - enable: true
    - watch:
      - file: nginx-config
```

### Top.sls — State Assignment

**`/srv/salt/top.sls`**:
```yaml
base:
  '*':
    - common.base
  'web*':
    - match: glob
    - nginx
  'G@os_family:Debian':
    - match: compound
    - apt_config
```

### Require / Watch / Onchanges

```yaml
# require — explicit dependency
app-directory:
  file.directory:
    - name: /opt/myapp
    - require:
      - pkg: app-packages

# watch — triggers mod_watch on change
app-service:
  service.running:
    - name: myapp
    - enable: true
    - watch:
      - file: app-config

# onchanges — run only if watched resource changed
app-restart:
  cmd.run:
    - name: systemctl restart myapp
    - onchanges:
      - file: app-config
```

### Jinja Templates

**`/srv/salt/nginx/files/nginx.conf.jinja`**:
```nginx
# Managed by Salt
user {{ salt['grains.get']('nginx:user', 'www-data') }};
worker_processes {{ grains['num_cpus'] }};
events {
  worker_connections {{ pillar.get('nginx:worker_connections', 1024) }};
}
http {
  include /etc/nginx/mime.types;
  {% if salt['pillar.get']('nginx:gzip', True) %}
  gzip on;
  gzip_types text/plain text/css application/json;
  {% endif %}
  include /etc/nginx/conf.d/*.conf;
}
```

### Grains and Pillars

```yaml
# Grains — static minion metadata (visible to all)
grains:
  os_family: Debian
  osrelease: 22.04
  num_cpus: 4
  fqdn: web01.example.com
  role: web_server

# Using grains in SLS
{% if grains['os_family'] == 'RedHat' %}
apache: { pkg.installed: [{ name: httpd }] }
{% elif grains['os_family'] == 'Debian' %}
apache: { pkg.installed: [{ name: apache2 }] }
{% endif %}
```

Custom grains (`/srv/salt/_grains/role.py`):
```python
def role():
    import os
    if os.path.exists('/etc/role'):
        with open('/etc/role') as f:
            return {'role': f.read().strip()}
    return {'role': 'unknown'}
```

```bash
salt '*' saltutil.sync_grains
salt '*' grains.item role
```

**Pillars** — secure, minion-specific data (not visible to other minions):

**`/srv/pillar/top.sls`**:
```yaml
base:
  '*':          [common]
  'web*':       [nginx]
  'G@env:prod': [secrets.prod]
```

**`/srv/pillar/nginx.sls`**:
```yaml
nginx:
  worker_processes: 4
  worker_connections: 2048
  gzip: true
  vhosts:
    example.com: { port: 443, ssl: true, cert: /etc/letsencrypt/live/example.com/fullchain.pem }
```

### Orchestration

**`/srv/salt/orch/update_all.sls`**:
```yaml
update-all:
  salt.state:
    - tgt: '*'
    - sls: common.update
verify-services:
  salt.function:
    - tgt: '*'
    - name: service.status
    - arg: [nginx]
    - require:
      - salt: update-all
```

```bash
salt-run state.orchestrate orch.update_all
```

---



---

[← Previous](06-6-saltstack-architecture.md) | [↑ Index](index.md) | [Next →](08-8-saltstack-advanced.md)
