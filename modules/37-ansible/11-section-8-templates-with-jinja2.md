## 🎨 Section 8: Templates with Jinja2

Jinja2 is Python's templating engine. Ansible uses it for `.j2` template files.

### Template File Example

```nginx
# nginx.conf.j2
worker_processes {{ ansible_facts['processor_cores'] }};

events {
    worker_connections {{ nginx_worker_connections | default(1024) }};
}

http {
    server {
        listen {{ http_port }};
        server_name {{ server_name }};

        location / {
            proxy_pass http://127.0.0.1:{{ app_port }};
        }

        {% if enable_ssl %}
        listen 443 ssl;
        ssl_certificate /etc/ssl/certs/{{ ssl_cert }};
        ssl_certificate_key /etc/ssl/private/{{ ssl_key }};
        {% endif %}
    }
}
```

### Using Templates in Playbooks

```yaml
- name: Deploy Nginx template
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: Reload Nginx
```

### Filters in Templates

```yaml
{{ variable | default('fallback') }}       # Default value
{{ list | unique }}                        # Remove duplicates
{{ list | join(', ') }}                    # Join list to string
{{ string | upper }}                       # Uppercase
{{ string | lower }}                       # Lowercase
{{ dict | to_json }}                       # Convert to JSON
{{ dict | to_yaml }}                       # Convert to YAML
{{ path | basename }}                      # Extract filename
{{ path | dirname }}                       # Extract directory
{{ ip | ipaddr('network') }}               # IP address filter
{{ 'hello' | regex_replace('^h', 'H') }}   # Regex replace
```

### Conditionals in Templates

```jinja2
{% if ansible_facts['os_family'] == 'Debian' %}
APT::Install-Recommends "0";
{% elif ansible_facts['os_family'] == 'RedHat' %}
installonly_limit = 3
{% endif %}
```

### Loops in Templates

```jinja2
# List all upstream servers
upstream backend {
{% for server in backend_servers %}
    server {{ server }}:{{ backend_port }};
{% endfor %}
}
```

---



---

[← Previous](10-section-7-variables-and-facts.md) | [↑ Index](index.md) | [Next →](12-section-9-conditionals-and-loops.md)
