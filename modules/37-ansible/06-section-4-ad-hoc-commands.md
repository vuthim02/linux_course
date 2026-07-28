## ⚡ Section 4: Ad-hoc Commands

Ad-hoc commands run a single module against hosts without a playbook.

### Ping Module — Test Connectivity

```bash
ansible all -m ping
```

```json
web1.example.com | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3"
    },
    "changed": false,
    "ping": "pong"
}
```

### Command Module — Run Any Command

```bash
ansible all -m command -a "uptime"
ansible all -m command -a "df -h"
ansible webservers -m command -a "free -m"
```

### Shell Module — Command with Shell Features

```bash
ansible all -m shell -a "echo $HOSTNAME && whoami"
ansible all -m shell -a "ps aux | grep nginx | wc -l"
```

### Copy Module — Copy Files to Remote

```bash
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts_backup mode=0644"
```

### Setup Module — Gather Facts

```bash
ansible localhost -m setup
ansible webservers -m setup -a "filter=ansible_os_family"
ansible all -m setup -a "filter=ansible_default_ipv4"
```

```json
"ansible_default_ipv4": {
    "address": "192.168.1.100",
    "broadcast": "192.168.1.255",
    "gateway": "192.168.1.1",
    "interface": "eth0",
    "macaddress": "aa:bb:cc:dd:ee:ff",
    "netmask": "255.255.255.0",
    "network": "192.168.1.0",
    "type": "ether"
}
```





[← Previous](05-section-3-inventory.md) | [↑ Index](index.md) | [Next →](07-section-5-playbooks.md)
