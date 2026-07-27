## 8. SaltStack Advanced

### salt-ssh (Agentless)

```bash
# /etc/salt/roster
web01:
  host: 10.0.0.5
  user: ubuntu
  sudo: true
  privkey: /root/.ssh/id_ed25519

salt-ssh '*' state.apply nginx
salt-ssh '*' cmd.run 'uptime'
```

### salt-cloud (Provisioning)

```yaml
# /etc/salt/cloud.providers.d/aws.conf
my-aws:
  provider: aws
  access_key: AKIA...
  secret_key: ...
  region: us-west-2

# /etc/salt/cloud.profiles.d/web.conf
web-ubuntu:
  provider: my-aws
  image: ami-0c55b159cbfafe1f0
  size: t3.medium
  script: bootstrap-salt.sh
```

```bash
salt-cloud -p web-ubuntu web01 web02 web03
salt-cloud -d web01
```

### Reactor System

```yaml
# /etc/salt/master.d/reactor.conf
reactor:
  - 'salt/minion/*/start':
    - /srv/reactor/sync_all.sls
  - 'salt/cloud/*/created':
    - /srv/reactor/new_vm.sls
```

**`/srv/reactor/new_minion.sls`**:
```yaml
accept_key:
  wheel.key.accept:
    - match: { id: {{ data['id'] }} }
add_dns:
  cmd.run:
    - tgt: dns-master
    - arg: ["{{ data['id'] }} IN A {{ data['ip_address'] }}"]
```

### Beacons (Monitoring Events)

```yaml
# /etc/salt/minion.d/beacons.conf
beacons:
  diskusage:
    - /: { minimum: 10% }
    - interval: 300
  load:
    - averages: { 1m: 4.0, 5m: 3.0 }
    - interval: 60
  service:
    - services: { nginx: { onchangeonly: true } }
```

---



---

[← Previous](07-7-saltstack-states.md) | [↑ Index](index.md) | [Next →](09-9-chef-architecture.md)
