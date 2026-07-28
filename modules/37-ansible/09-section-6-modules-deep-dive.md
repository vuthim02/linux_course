## 🧩 Section 6: Modules Deep Dive

### Package Module

```yaml
- name: Install package (cross-platform)
  ansible.builtin.package:
    name: nginx
    state: present  # present | absent | latest

- name: Install with apt
  ansible.builtin.apt:
    name: "{{ packages }}"
    state: present
    update_cache: yes

- name: Install with yum
  ansible.builtin.yum:
    name: httpd
    state: latest
```

### Service Module

```yaml
- name: Start and enable service
  ansible.builtin.service:
    name: nginx
    state: started     # started | stopped | restarted | reloaded
    enabled: yes       # start on boot
```

### Copy Module

```yaml
- name: Copy file with permissions
  ansible.builtin.copy:
    src: /local/file.txt
    dest: /remote/file.txt
    owner: root
    group: root
    mode: '0644'
    backup: yes       # backup existing file before overwriting
```

### Template Module

```yaml
- name: Deploy templated config
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: '0644'
```

### File Module

```yaml
- name: Create directory
  ansible.builtin.file:
    path: /var/www/myapp
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'

- name: Create symlink
  ansible.builtin.file:
    src: /opt/app/current
    dest: /var/www/myapp
    state: link

- name: Create empty file
  ansible.builtin.file:
    path: /etc/myapp/config
    state: touch
    mode: '0644'
```

### User Module

```yaml
- name: Create user with SSH key
  ansible.builtin.user:
    name: deploy
    shell: /bin/bash
    groups: sudo
    append: yes
    state: present

- name: Set authorized SSH key
  ansible.posix.authorized_key:
    user: deploy
    state: present
    key: "{{ lookup('file', '/home/admin/.ssh/deploy_key.pub') }}"
```

### Lineinfile Module

```yaml
- name: Ensure line exists in file
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^PermitRootLogin'
    line: 'PermitRootLogin no'
    backup: yes

- name: Ensure line is absent
  ansible.builtin.lineinfile:
    path: /etc/hosts
    line: '192.168.1.100 old-server'
    state: absent
```

### Systemd Module

```yaml
- name: Reload systemd daemon
  ansible.builtin.systemd:
    daemon_reload: yes

- name: Start custom service
  ansible.builtin.systemd:
    name: myapp
    state: started
    enabled: yes
    daemon_reload: yes
```

### Get URL Module

```yaml
- name: Download file from URL
  ansible.builtin.get_url:
    url: https://releases.ubuntu.com/22.04/ubuntu-22.04-desktop.iso
    dest: /tmp/ubuntu.iso
    checksum: sha256:abc123...
    mode: '0644'
```

### Unarchive Module

```yaml
- name: Extract archive
  ansible.builtin.unarchive:
    src: /tmp/app.tar.gz
    dest: /opt/app
    remote_src: yes    # source is already on remote
    owner: www-data
    group: www-data
```

### Fetch Module

```yaml
- name: Fetch file from remote to local
  ansible.builtin.fetch:
    src: /var/log/syslog
    dest: /backups/logs/{{ inventory_hostname }}/syslog
    flat: no
```





[← Previous](08-level-2-intermediary-daily-administration.md) | [↑ Index](index.md) | [Next →](10-section-7-variables-and-facts.md)
