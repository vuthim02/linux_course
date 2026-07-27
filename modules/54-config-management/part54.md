# 🐧 Linux System Administrator — Complete Course
## Part 54 of ∞: Advanced Configuration Management — Puppet, Salt, Chef

---

> **Reverse Engineering Approach:** We take a web server stack (Nginx, firewall, users, SSH keys, monitoring) and implement it identically in Puppet, Salt, and Chef. By dismantling each implementation, you will understand not just syntax but the architecture, philosophy, and trade-offs of each tool.

---

## 1. Configuration Management Paradigms

### Declarative vs Procedural

| Aspect | Declarative | Procedural |
|--------|------------|------------|
| What you write | Desired end state | Step-by-step instructions |
| How it runs | Tool decides order | You control order |
| Idempotency | Inherent | Must be coded manually |
| Examples | Puppet, Salt states, Chef, Terraform | Shell scripts, Ansible playbooks (mostly) |

Declarative: `package { 'nginx': ensure => installed }` — say *what*, not *how*.
Procedural: `apt-get install -y nginx` — say *how*, step by step.

### Master/Agent vs Agentless vs Solo

| Model | Description | Tools |
|-------|-------------|-------|
| Master/Agent | Central server + client daemon | Puppet, Salt (minion), Chef |
| Agentless | Push via SSH, no agent | Ansible, Salt SSH |
| Solo/Local | No server, apply locally | `puppet apply`, chef-zero |

### Pull vs Push

- **Pull**: Agents periodically connect to master, fetch catalog, apply. Scales to thousands. Default for Puppet and Chef.
- **Push**: Master pushes commands. Salt supports both — push via ZeroMQ or pull via scheduled states.
- **Hybrid**: Salt master sends "run now" signal, minion pulls state and applies.

### Idempotency

Operation is **idempotent** if applying it N times produces the same result as one application. `ensure => installed` checks `dpkg -l` / `rpm -q` before installing. `file` resource checks content checksum. If already correct, skip.

### Resource Abstraction Layer

Each tool wraps OS-native operations behind a **resource/provider** abstraction:

```puppet
package { 'nginx': ensure => installed }
```

On Ubuntu: `apt-get install nginx`. On RHEL: `yum install nginx`. On FreeBSD: `pkg install nginx`. The provider handles platform details. The resource declaration is identical.

---

## 2. Puppet Architecture

### Core Components

```
                    ┌──────────────────────┐
                    │  Puppet Server (JRuby)│
                    │  Port 8140 HTTPS     │
                    └──────┬───────────────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
     ┌──────▼──────┐ ┌────▼────┐  ┌──────▼─────┐
     │ Puppet Agent│ │PuppetDB │  │  r10k      │
     │ (Ruby,      │ │(Postgres│  │ (Git env   │
     │  systemd)   │ │ +Solr) │  │  builder)  │
     └─────────────┘ └─────────┘  └────────────┘
```

1. **Puppet Server**: JVM-based, port 8140 HTTPS. Compiles **catalogs** for each agent. Certificate-based auth.
2. **PuppetDB**: Stores facts, catalogs, reports. PostgreSQL. Queryable via PQL. Used for exported resources.
3. **Puppet Agents**: Ruby daemon. Runs as `puppet.service`. Submits facts, receives catalog, applies it, reports.
4. **r10k**: Git-based environment deployment. Reads `Puppetfile`, deploys modules per environment.
5. **Puppetfile**: Lists modules with versions (like Gemfile for Puppet).

### Certificate Signing

```
Agent → CSR → Puppet Server → autosign or pending → puppetserver ca sign --certname <name>
```

### Environments and Modulepath

```
/etc/puppetlabs/code/environments/
├── production/manifests/site.pp
├── production/modules/{nginx,stdlib,...}
├── production/Puppetfile
├── development/...
└── testing/...
```

Each environment has its own `modulepath` — different module versions per env. r10k builds environments from Git branches.

---

## 3. Puppet DSL

### Resources

```puppet
file { '/etc/nginx/nginx.conf':
  ensure  => file, owner => 'root', group => 'root', mode => '0644',
  content => template('nginx/nginx.conf.erb'),
  require => Package['nginx'],
}
package { 'nginx': ensure => installed }
service { 'nginx':
  ensure => running, enable => true,
  subscribe => File['/etc/nginx/nginx.conf'],
}
user { 'webapp':
  ensure => present, uid => 2001, gid => 'www-data',
  home => '/home/webapp', managehome => true,
}
exec { 'reload-systemd':
  command => '/bin/systemctl daemon-reload',
  refreshonly => true,
  subscribe => File['/etc/systemd/system/webapp.service'],
}
cron { 'rotate-logs':
  command => '/usr/local/bin/rotate-logs', user => 'root',
  hour => 3, minute => 0,
}
```

### Classes

```puppet
class nginx (
  String $worker_processes = 'auto',
  Hash   $vhosts           = {},
) {
  package { 'nginx': ensure => installed }
  file { '/etc/nginx/nginx.conf':
    content => epp('nginx/nginx.conf.epp', {
      'worker_processes' => $worker_processes,
      'vhosts'           => $vhosts,
    }),
    require => Package['nginx'],
    notify  => Service['nginx'],
  }
  $vhosts.each |String $name, Hash $config| {
    file { "/etc/nginx/conf.d/${name}.conf":
      content => epp('nginx/vhost.conf.epp', { 'name' => $name, 'config' => $config }),
      notify  => Service['nginx'],
    }
  }
  service { 'nginx': ensure => running, enable => true }
}
```

### Defined Types

```puppet
define nginx::vhost (
  String $server_name, String $root = "/var/www/${title}",
  Integer $port = 80, Boolean $ssl = false,
) {
  file { "/etc/nginx/sites-available/${title}":
    content => epp('nginx/vhost.conf.epp', {
      'server_name' => $server_name, 'root'  => $root,
      'port'        => $port,        'ssl'  => $ssl,
    }),
    notify  => Service['nginx'],
  }
  file { "/etc/nginx/sites-enabled/${title}":
    ensure => link, target => "/etc/nginx/sites-available/${title}",
    notify => Service['nginx'],
  }
}
```

### Relationships

```puppet
Package['nginx'] -> File['/etc/nginx/nginx.conf'] ~> Service['nginx']
# -> before    <- require    ~> notify    <~ subscribe
```

### Variables, Facts, Templates

```puppet
$app_port = 8080
$facts['os']['family']                   # 'Debian' or 'RedHat'
$facts['networking']['fqdn']
$facts['memory']['system']['available']
```

**ERB Template** `templates/nginx.conf.erb`:
```erb
worker_processes <%= @worker_processes %>;
events { worker_connections <%= @worker_connections %>; }
http {
  include /etc/nginx/mime.types;
  <% if @enable_gzip %>gzip on; gzip_types text/plain text/css; <% end %>
  include /etc/nginx/conf.d/*.conf;
}
```

### Hiera (Data Separation)

**`hiera.yaml`**:
```yaml
version: 5
defaults: { datadir: data, data_hash: yaml_data }
hierarchy:
  - name: "Per-node data"     path: "nodes/%{::trusted.certname}.yaml"
  - name: "Per-OS data"       path: "os/%{::facts.os.family}/%{::facts.os.release.major}.yaml"
  - name: "Common data"       path: "common.yaml"
```

**`data/common.yaml`**:
```yaml
nginx::worker_processes: auto
nginx::enable_gzip: true
nginx::vhosts:
  example.com: { port: 443, ssl: true }
ntp::servers: [0.pool.ntp.org, 1.pool.ntp.org]
```

### Catalog Compilation Flow

```
1. Agent sends facts → Puppet Server (HTTPS POST /puppet/v3/catalog)
2. Server loads site.pp, matches node block
3. Parser tokenizes → AST (Abstract Syntax Tree)
4. Evaluator: conditionals, loops, class inclusion, Hiera lookups
5. Resolves dependencies (require/before/notify/subscribe)
6. Compiler builds catalog (JSON DAG of resources with edges)
7. Server signs catalog with server cert → agent
8. Agent walks DAG, per resource: calls provider → checks state vs catalog
9. Out of sync → converge; in sync → skip
10. Agent sends report → PuppetDB
```

---

## 4. Puppet Modules and Forge

### Using Forge Modules (Puppetfile)

```puppet
forge 'https://forge.puppet.com'
mod 'puppetlabs/stdlib',      '9.4.0'
mod 'puppetlabs/concat',      '8.1.0'
mod 'puppet/nginx',           '3.3.0'
mod 'puppetlabs/postgresql',  '9.3.0'
mod 'puppetlabs/firewall',    '3.4.0'
mod 'profile_base',
  git: 'https://git.example.com/puppet/profile_base.git',
  ref: 'v1.2.3'
```

### Module Skeleton

```
my_module/
├── manifests/init.pp, install.pp, config.pp, service.pp
├── templates/config.epp, config.erb
├── files/default.conf
├── lib/puppet/type/         # custom types
├── lib/puppet/provider/     # custom providers
├── lib/facter/              # custom facts
├── data/common.yaml
├── spec/classes/            # unit tests
├── metadata.json
└── README.md
```

### metadata.json

```json
{
  "name": "myorg-apache", "version": "1.2.0",
  "dependencies": [
    { "name": "puppetlabs/stdlib", "version_requirement": ">= 6.0.0 < 10.0.0" }
  ]
}
```

### Dependency Resolution (r10k)

```bash
r10k puppetfile install --moduledir=/etc/puppetlabs/code/environments/production/modules
r10k deploy environment production -v
```

---

## 5. Puppet in Practice — Roles and Profiles

### The Pattern

```
site.pp → node 'web01' { role('web_server') }

roles/manifests/web_server.pp
  → class role::web_server {
      include profile::base
      include profile::nginx
      include profile::firewall
    }

profiles/manifests/
├── base.pp   → class profile::base { ... }     # OS config, users, repos
├── nginx.pp  → class profile::nginx { ... }    # Nginx with business logic
└── firewall.pp → class profile::firewall { .. } # Firewall rules
```

**Roles** are pure compositions — never contain business logic.
**Profiles** wrap upstream Forge modules with your org's defaults:

```puppet
class profile::nginx (
  Array[String] $vhosts    = lookup('profile::nginx::vhosts'),
  Integer       $worker    = lookup('profile::nginx::worker_process'),
) {
  class { 'nginx': worker_processes => $worker }
  $vhosts.each |$vhost| {
    nginx::resource::server { $vhost['server_name']:
      listen_port => $vhost['port'], ssl => $vhost['ssl'],
      ssl_cert    => $vhost['ssl_cert'], ssl_key => $vhost['ssl_key'],
      www_root    => $vhost['docroot'],
    }
  }
  include profile::monitoring::nginx
}
```

### hiera-eyaml for Secrets

```bash
eyaml createkeys
eyaml encrypt -s 's3kr3t!' --pkcs7-private-key=pkcs7_key.pem --pkcs7-public-key=pkcs7_key.pem
```

```yaml
# data/common.yaml
profile::app::db_password: >
  ENC[PKCS7,MIIBeQYJKoZIhvcNAQcDoIIB...]
```

---

## 6. SaltStack Architecture

### Core Components

```
                   ┌──────────────────────────┐
                   │     Salt Master           │
                   │  Port 4505 (ZMQ pub)      │
                   │  Port 4506 (ZMQ req/rep)  │
                   │  Event bus (ZMQ)         │
                   └──────┬──────────┬────────┘
                          │          │
                   ZMQ pub/sub   ZMQ req/rep
                          │          │
            ┌─────────────┼──────────┼──────────┐
            │             │          │          │
     ┌──────▼──────┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────┐
     │  Minion 1   │ │ Minion2│ │ Minion3│ │...500  │
     └─────────────┘ └────────┘ └────────┘ └────────┘
```

1. **Salt Master**: Python. Port 4505 (publish bus — all minions subscribe), 4506 (request/response). Manages keys, pillars, file server.
2. **Minion**: Python daemon `salt-minion`. Subscribes to 4505, sends results via 4506.
3. **ZeroMQ**: Async message transport. Pub/sub (master → all) + request/response (master ↔ minion).
4. **Event Bus**: All components publish events. Reactor listens and fires actions.
5. **Minion Keys**: RSA key pairs. Accepted via `salt-key -A`.

### Key Management

```bash
salt-key -L          # List all keys
salt-key -a web01    # Accept a key
salt-key -A          # Accept all unaccepted
salt-key -d web01    # Delete
```

---

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

## 9. Chef Architecture

### Core Components

```
                    ┌─────────────────────────┐
                    │   Chef Infra Server      │
                    │  Erlang, Port 443 HTTPS  │
                    │  PostgreSQL + Solr/ES    │
                    └──────────┬──────────────┘
                               │
                    ┌──────────▼──────────────┐
                    │   Chef Workstation      │
                    │  knife, berks, kitchen  │
                    └──────────┬──────────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
     ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
     │ chef-client │   │ chef-client │   │ chef-client │
     │ + Ohai      │   │ + Ohai      │   │ + Ohai      │
     └─────────────┘   └─────────────┘   └─────────────┘
```

1. **Chef Infra Server**: Erlang backend. Stores cookbooks, nodes, roles, environments, data bags. Search via Solr/Elasticsearch. PostgreSQL persistence.
2. **Chef Workstation**: Admin tools: `knife`, `berks`, `kitchen`, `chef-client`.
3. **Chef Infra Client**: Ruby agent. Runs Ohai for system profiling, then connects to Server, downloads run_list, compiles and applies resources.
4. **Ohai**: System profiling — platform, CPU, memory, network, filesystem → `node['...']`.
5. **Chef Supermarket**: `https://supermarket.chef.io` — community cookbooks.
6. **chef-zero**: In-memory Chef Server for testing. `chef-client --local-mode`.

### Bootstrap Flow

```bash
knife bootstrap 10.0.0.5 \
  --ssh-user ubuntu --sudo \
  --node-name web01 \
  --run-list 'role[web_server]'
# 1. SSH to node, 2. Install chef-client (omnibus), 3. Create /etc/chef/client.rb
# 4. Run chef-client: registers as web01, downloads run_list, runs Ohai, applies
```

---

## 10. Chef DSL

### Resources

```ruby
package 'nginx' do
  version '1.24.0'
  action :install
end

template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    worker_processes: node['nginx']['worker_processes'],
    worker_connections: node['nginx']['worker_connections'],
  )
  notifies :reload, 'service[nginx]'
end

service 'nginx' do
  supports reload: true, restart: true, status: true
  action [:enable, :start]
end

user 'webapp' do
  uid 2001
  gid 'www-data'
  home '/home/webapp'
  manage_home true
  action :create
end

execute 'reload-systemd' do
  command 'systemctl daemon-reload'
  action :nothing
  subscribes :run, 'template[/etc/systemd/system/webapp.service]'
end

directory '/opt/myapp' do
  owner 'webapp'
  group 'www-data'
  mode '0755'
  recursive true
end

cookbook_file '/etc/nginx/default.conf' do
  source 'default.conf'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :reload, 'service[nginx]'
end

cron 'rotate-logs' do
  command '/usr/local/bin/rotate-logs'
  user 'root'
  hour 3
  minute 0
end
```

### Recipes

```ruby
# recipes/default.rb
include_recipe 'nginx::install'
include_recipe 'nginx::config'
include_recipe 'nginx::service'

# recipes/install.rb
package 'nginx' do
  action :install
end
case node['platform_family']
when 'debian' then include_recipe 'nginx::install_debian'
when 'rhel'   then include_recipe 'nginx::install_rhel'
end

# recipes/config.rb
template '/etc/nginx/nginx.conf' do
  source 'nginx.conf.erb'
  variables(
    worker_processes: node['nginx']['worker_processes'] || 'auto',
    worker_connections: node['nginx']['worker_connections'] || 1024,
    gzip: node['nginx']['gzip'] || true,
  )
  notifies :reload, 'service[nginx]'
end

# Dynamic config from search
search(:node, "role:web_server AND chef_environment:#{node.chef_environment}").each do |n|
  template "/etc/nginx/conf.d/#{n['fqdn']}.conf" do
    source 'upstream.conf.erb'
    variables(backend_host: n['ipaddress'], backend_port: n['nginx']['port'] || 8080)
    notifies :reload, 'service[nginx]'
  end
end
```

### Attributes

**`attributes/default.rb`**:
```ruby
default['nginx']['worker_processes'] = 'auto'
default['nginx']['worker_connections'] = 1024
default['nginx']['gzip'] = true
```

**Precedence** (lowest → highest): `default` → `force_default` → `normal` → `override` → `force_override` → `automatic` (Ohai, cannot be overridden).

### Templates (ERB)

**`templates/default/nginx.conf.erb`**:
```nginx
# Managed by Chef
user <%= @user || 'www-data' %>;
worker_processes <%= @worker_processes %>;
events { worker_connections <%= @worker_connections %>; }
http {
  include /etc/nginx/mime.types;
  <% if @gzip %>gzip on; gzip_types text/plain text/css; <% end %>
  include /etc/nginx/conf.d/*.conf;
}
```

### Data Bags

```bash
knife data bag create users
```

```json
// data_bags/users/alice.json
{ "id": "alice", "uid": 1001, "groups": ["sudo","www-data"],
  "ssh_keys": ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA..."] }
```

```ruby
# Use in recipe
search(:users, '*:*').each do |u|
  user u['id'] { uid u['uid']; groups u['groups']; manage_home true; action :create }
  u['ssh_keys'].each_with_index do |key, i|
    file "/home/#{u['id']}/.ssh/authorized_keys" do
      content "#{key}\n"; mode '0600'; owner u['id']
    end
  end
end
```

### Encrypted Data Bags

```bash
openssl rand -base64 512 > secret.key
knife data bag create passwords --secret-file secret.key
knife data bag from file passwords db.json --secret-file secret.key
# db.json: { "id": "db", "password": "SuperS3kr3t!", "host": "db01" }
```

```ruby
secret = Chef::EncryptedDataBagItem.load('passwords', 'db')
template '/etc/myapp/database.yml' do
  source 'database.yml.erb'
  sensitive true
  variables(password: secret['password'], host: secret['host'])
end
```

### Roles and Environments

**`roles/web_server.json`**:
```json
{
  "name": "web_server",
  "run_list": ["recipe[base]", "recipe[nginx]", "recipe[firewall]"],
  "default_attributes": { "nginx": { "worker_processes": 4 } }
}
```

**`environments/production.json`**:
```json
{
  "name": "production",
  "cookbook_versions": { "nginx": "~> 5.0" },
  "override_attributes": { "nginx": { "worker_processes": 8 } }
}
```

### Search API

```ruby
search(:node, 'platform:ubuntu')
search(:node, 'platform:ubuntu AND chef_environment:production')
search(:node, 'role:web_server OR role:api_server')
search(:node, 'fqdn:*.example.com')
search(:node, 'role:web_server', filter_result: { 'name' => ['name'], 'ip' => ['ipaddress'] })
```

Search queries Chef Server's Solr/ES index, updated after every chef-client run.

---

## 11. Chef in Practice

### Berksfile (Cookbook Dependencies)

```ruby
source 'https://supermarket.chef.io'
cookbook 'nginx', '~> 12.0'
cookbook 'firewall', '~> 3.0'
cookbook 'myapp', path: './cookbooks/myapp'
cookbook 'internal-tool', git: 'https://git.example.com/chef/internal-tool.git', branch: 'main'
```

```bash
berks install
berks upload
berks vendor cookbooks/
```

### Test-Kitchen (Integration Testing)

**`kitchen.yml`**:
```yaml
driver:
  name: vagrant
provisioner:
  name: chef_zero
  product_version: '18.3.0'
verifier:
  name: inspec
platforms:
  - name: ubuntu-22.04
  - name: centos-stream-9
suites:
  - name: default
    run_list: ["recipe[myapp::default]"]
    attributes: { myapp: { port: 8080 } }
```

```bash
kitchen list
kitchen converge ubuntu-2204
kitchen verify ubuntu-2204
kitchen test
```

### ChefSpec (Unit Testing)

```ruby
require 'spec_helper'
describe 'myapp::default' do
  platform 'ubuntu', '22.04'
  it 'installs nginx' do
    expect(chef_run).to install_package('nginx')
  end
  it 'creates nginx config' do
    expect(chef_run).to create_template('/etc/nginx/nginx.conf').with(owner: 'root', mode: '0644')
  end
  it 'enables and starts nginx' do
    expect(chef_run).to enable_service('nginx')
    expect(chef_run).to start_service('nginx')
  end
end
```

### Policyfiles (Replacing Roles + Environments)

```ruby
# Policyfile.rb
name 'myapp'
default_source :supermarket
run_list ['recipe[base]', 'recipe[myapp::default]']
cookbook 'myapp', path: './cookbooks/myapp'
default['myapp']['version'] = '1.0.0'
```

```bash
chef install Policyfile.rb          # Generate Policyfile.lock.json
chef push production Policyfile.rb  # Push to server
knife node policy set web01 myapp production
```

---

## 12. Comparative Analysis

| Dimension | Puppet | Salt | Chef | Ansible |
|-----------|--------|------|------|---------|
| Language | Ruby DSL → catalog JSON | YAML + Jinja | Ruby DSL | YAML |
| Architecture | Master/Agent | Master/Minion (or SSH) | Server/Client | Agentless (SSH) |
| Transport | HTTPS (REST) | ZeroMQ (pub/sub) | HTTPS (REST) | SSH |
| Push/Pull | Pull | Both (push default) | Pull | Push |
| Idempotency | Built-in (catalog) | Built-in (state) | Built-in (resource) | YAML modules |
| State storage | PuppetDB (Postgres) | Master memory + file | Chef Server (Solr+PG) | None (stateless) |
| Scale | 1K-10K+ nodes | 1K-10K+ nodes | 1K-5K nodes | 500-1K (SSH) |
| Learning curve | Medium (Ruby DSL) | Low (YAML+Jinja) | Medium-High (Ruby) | Low (YAML) |
| Windows | Good | Good | Excellent | Good |
| Container native | Poor | Fair | Poor | Excellent |
| Community | Large (Forge) | Medium | Large (Supermarket) | Largest (Galaxy) |
| Enterprise | Puppet Enterprise | SaltStack (VMware) | Chef (Progress) | Red Hat |
| Testing | rspec-puppet, beaker | testinfra | ChefSpec, test-kitchen | molecule |
| Secrets | hiera-eyaml | GPG renderer, vault | encrypted data bags | ansible-vault |

### When to Use Which

**Puppet**: Large standardized fleets (1K-10K+), heavy compliance (PCI-DSS, SOC2, HIPAA). Banks, government, large enterprises that need a single source of truth with strong data separation.

**Salt**: High-frequency operations, event-driven infrastructure at scale. SRE teams needing both config and orchestration in one tool. Hybrid push/pull environments.

**Chef**: Ruby-shop teams, DevOps-mature organizations with strong testing culture (ChefSpec + test-kitchen). Treating infrastructure as a "compiled" API.

**Ansible**: Simplest setup (no agents). Best for small-medium infrastructure, network automation, containerized envs, CI/CD tasks, teams new to CM.

### Strengths and Weaknesses

**Puppet**: ✅ Strong resource abstraction (providers for every OS), Hiera data separation is mature, Roles/Profiles forces clean architecture, PuppetDB queries. ❌ JRuby server complex to debug (memory, GC), slow run cycle (default 30 min), verbose DSL for simple tasks.

**Salt**: ✅ ZeroMQ fast (millisecond pub/sub), event-driven reactor unique, flexible targeting (grains, compound, glob), agentless mode. ❌ YAML+Jinja becomes unmanageable without discipline, master is SPOF (mitigated by multi-master), state ordering bugs in complex trees.

**Chef**: ✅ Ruby DSL expressive, Ohai richest introspection, Search API makes dynamic config natural, best testing story. ❌ Ruby requires real programming, Chef Server complex (Erlang/Solr), attribute precedence confusing, slower converge times.

---

## 13. Modern Era

### Shift to GitOps (ArgoCD, Flux)

Git repo as source of truth → operator continuously converges cluster. Natural evolution of CM principles. The operator is like a Puppet agent or Salt minion for Kubernetes.

### Push-Based Lightweight Config (Ansible)

Industry moving toward simpler, push-based approaches. Ansible dominates server-level config in cloud-native environments. No agent to maintain. Ephemeral infrastructure uses "patch on boot" via cloud-init + Ansible pull.

### Immutable Infrastructure (Packer)

Bake AMIs/VM images with everything pre-configured. No mutations at runtime. Change config → bake new image → redeploy. Reduces need for runtime CM.

### Containers Reducing CM Needs

- **Containers took over**: Application deployment, dependency management, environment config.
- **CM still does**: Base OS hardening (SSH, NTP, kernel params), compliance (CIS benchmarks), stateful services (databases), legacy systems, monitoring agents, log shippers.

### Where Traditional CM Still Shines

1. **Stateful servers**: Databases, message queues, monitoring infra
2. **Compliance**: CIS benchmarks, DISA STIGs, PCI-DSS — automated compliance checking
3. **Edge/IoT**: Small-footprint agents (Salt on Raspberry Pi)
4. **Bare metal**: PXE boot → CM applies full config
5. **Legacy systems**: Pre-container apps on RHEL 7 / Ubuntu 16.04
6. **Network devices**: Ansible has strongest network module ecosystem
7. **Hybrid cloud**: Same CM across on-prem, AWS, Azure, GCP

---

## 15 Hands-On Practices

### Practice 1: Install Puppet Server and Agent, Sign Certs

```bash
# MASTER (puppet.example.com)
wget -O /tmp/puppet-release.deb https://apt.puppet.com/puppet8-release-jammy.deb
dpkg -i /tmp/puppet-release.deb && apt-get update && apt-get install -y puppetserver
sed -i 's/-Xms2g -Xmx2g/-Xms512m -Xmx512m/' /etc/default/puppetserver
systemctl start puppetserver && systemctl enable puppetserver

# AGENT (web01.example.com)
wget -O /tmp/puppet-release.deb https://apt.puppet.com/puppet8-release-jammy.deb
dpkg -i /tmp/puppet-release.deb && apt-get update && apt-get install -y puppet-agent
echo -e "[main]\nserver = puppet.example.com\ncertname = web01.example.com" > /etc/puppetlabs/puppet/puppet.conf
puppet agent -t  # Generate CSR

# MASTER: sign, then AGENT: run again
puppetserver ca sign --certname web01.example.com && puppet agent -t
```

### Practice 2: Write Puppet Manifest to Install Nginx with Custom index.html

```puppet
node 'web01.example.com' {
  package { 'nginx': ensure => installed }
  service { 'nginx': ensure => running, enable => true, require => Package['nginx'] }
  file { '/var/www/html/index.html':
    content => '<h1>Managed by Puppet</h1><p>Host: <%= @facts["networking"]["hostname"] %></p>',
    mode    => '0644', owner => 'www-data', group => 'www-data',
  }
}
```

```bash
puppet agent -t && curl http://web01.example.com
```

### Practice 3: Create Module with Classes, Use Hiera

```puppet
# modules/motd/manifests/init.pp
class motd (String $message = 'Welcome', Array $admin_emails = []) {
  file { '/etc/motd':
    content => epp('motd/motd.epp', { 'message' => $message, 'hostname' => $facts['networking']['hostname'],
      'admin_emails' => $admin_emails, 'uptime' => $facts['system_uptime']['uptime_string'] }),
    mode    => '0644',
  }
}
```

```yaml
# data/nodes/web01.example.com.yaml
motd::message: "Web Server Node"
motd::admin_emails: [ops@example.com]
```

### Practice 4: Implement Roles and Profiles Pattern

```puppet
# site.pp
node 'web01.example.com' { role('web_server::standard') }

# roles/manifests/web_server/standard.pp
class role::web_server::standard {
  include profile::base; include profile::nginx; include profile::firewall
  include profile::monitoring::node_exporter
}

# profiles/manifests/base.pp
class profile::base (
  Array[String] $packets  = lookup('profile::base::packages'),
  Array[Hash]   $users    = lookup('profile::base::users'),
  Integer       $ssh_port = lookup('profile::base::ssh_port'),
) {
  $packets.each |$pkg| { package { $pkg: ensure => installed } }
  $users.each |$u| {
    user { $u['username']: ensure => present, uid => $u['uid'], groups => $u['groups'],
           managehome => true }
    $u['ssh_keys'].each |$i, $k| {
      ssh_authorized_key { "${u['username']}-${i}": user => $u['username'], type => $k[0], key => $k[1] }
    }
  }
  file_line { 'ssh-port': path => '/etc/ssh/sshd_config', line => "Port ${ssh_port}", match => '^#?Port ',
    notify => Service['ssh'] }
  service { 'ssh': ensure => running, enable => true }
}
```

### Practice 5: Install Salt Master and Minion, Accept Keys, Ping Test

```bash
# MASTER
apt-get install -y salt-master
echo -e "interface: 0.0.0.0\nauto_accept: False" > /etc/salt/master.d/local.conf
systemctl enable --now salt-master

# MINION
apt-get install -y salt-minion
echo -e "master: salt.example.com\nid: web01.example.com" > /etc/salt/minion.d/local.conf
systemctl enable --now salt-minion

# MASTER
salt-key -A
salt 'web01*' test.ping   # → True
```

### Practice 6: Write SLS to Manage Users and SSH Keys

**`/srv/salt/users/init.sls`**:
```yaml
{% for user, config in pillar.get('users', {}).items() %}
{{ user }}-user:
  user.present:
    - name: {{ user }}
    - uid: {{ config.uid }}
    - groups: {{ config.groups | join(', ') }}
    - home: /home/{{ user }}
    - createhome: true
{{ user }}-ssh-dir:
  file.directory:
    - name: /home/{{ user }}/.ssh
    - user: {{ user }}
    - mode: 700
    - require:
      - user: {{ user }}-user
{% for key in config.get('ssh_keys', []) %}
{{ user }}-ssh-{{ loop.index }}:
  ssh_auth.present:
    - name: {{ key }}
    - user: {{ user }}
    - require:
      - file: {{ user }}-ssh-dir
{% endfor %}
{% endfor %}
```

**`/srv/pillar/users.sls`**:
```yaml
users:
  alice: { uid: 1001, groups: sudo,www-data, ssh_keys: [ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...] }
  bob:   { uid: 1002, groups: www-data, ssh_keys: [ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...] }
```

```bash
salt 'web01*' state.apply users
```

### Practice 7: Use Pillars for Secrets and Grains for Targeting

```yaml
# /srv/pillar/secrets.sls
secrets:
  db: { password: "MCPVbR6xKzq2!mN9", connection: "postgresql://app:MCPVbR6xKzq2!mN9@db01:5432/myapp" }
```

```yaml
# /srv/salt/app/init.sls
db-config:
  file.managed:
    - name: /etc/myapp/database.yml
    - contents: |
        password: {{ pillar.get('secrets:db:password') }}
        host: db01
    - mode: 600
```

```bash
salt 'web01*' grains.setval role web_server
salt -C 'G@role:web_server and G@environment:prod' test.ping
```

### Practice 8: Create Salt Orchestration

**`/srv/salt/orch/rolling_update.sls`**:
```yaml
canary-group:
  salt.state:
    - tgt: 'G@canary:true'
    - tgt_type: compound
    - sls: apex.update
    - batch: 1
    - fail_hard: true
main-fleet:
  salt.state:
    - tgt: 'web* and not G@canary:true'
    - tgt_type: compound
    - sls: apex.update
    - require:
      - salt: canary-group
    - batch: 5
```

```bash
salt-run state.orchestrate orch.rolling_update
```

### Practice 9: Install Chef Server and Workstation, Bootstrap a Node

```bash
# SERVER
dpkg -i chef-server-core_15.10.0-1_amd64.deb && chef-server-ctl reconfigure
chef-server-ctl user-create admin Admin User admin@example.com 'P@ssw0rd!' --filename /root/admin.pem
chef-server-ctl org-create myorg 'My Org' --association_user admin --filename /root/myorg-validator.pem

# WORKSTATION
dpkg -i chef-workstation_23.12.1055-1_amd64.deb
cat > ~/.chef/knife.rb << 'EOF'
node_name 'admin'
client_key '/root/admin.pem'
chef_server_url 'https://chef.example.com/organizations/myorg'
cookbook_path ['/root/cookbooks']
EOF

# BOOTSTRAP
knife bootstrap 10.0.0.5 --ssh-user ubuntu --sudo --node-name web01 --run-list 'role[web_server]'
```

### Practice 10: Write Chef Cookbook for Apache with Template

```ruby
# cookbooks/apache/recipes/default.rb
case node['platform_family']
when 'debian' then (pkg='apache2'; svc='apache2'; conf='/etc/apache2')
when 'rhel'   then (pkg='httpd';   svc='httpd';   conf='/etc/httpd')
end

package pkg { action :install }

template "#{conf}/ports.conf" do
  source 'ports.conf.erb'
  variables(listen_ports: node['apache']['listen_ports'] || [80, 443])
  notifies :restart, "service[#{svc}]"
end

service svc { action [:enable, :start]; supports reload: true }

node['apache']['modules'].each do |mod|
  execute "a2enmod #{mod}" do
    command "a2enmod #{mod}"
    not_if { File.exist?("/etc/apache2/mods-enabled/#{mod}.load") }
    notifies :restart, "service[#{svc}]"
  end
end

cookbook_file '/var/www/html/index.html' do
  source 'index.html'; owner 'www-data'; mode '0644'
end
```

```erb
<%# ports.conf.erb -%>
Listen <%= @listen_ports.join(' ') %>
NameVirtualHost *:80
```

### Practice 11: Use Encrypted Data Bags for Credentials

```bash
openssl rand -base64 512 > /root/encrypted_data_bag_secret
knife data bag create secrets --secret-file /root/encrypted_data_bag_secret
knife data bag from file secrets db.json --secret-file /root/encrypted_data_bag_secret
# db.json: { "id": "db", "password": "s3kr3t!", "host": "db01" }
```

```ruby
secret = Chef::EncryptedDataBagItem.load('secrets', 'db')
template '/etc/myapp/database.yml' do
  source 'database.yml.erb'
  sensitive true
  variables(password: secret['password'], host: secret['host'])
end
```

### Practice 12: Run Chef in Local Mode (Chef-Zero)

```bash
mkdir -p /tmp/chef-test/cookbooks/demo/recipes
cat > /tmp/chef-test/cookbooks/demo/recipes/default.rb << 'RUBY'
file '/tmp/chef-demo.txt' do
  content "Chef Zero test at #{Time.now}\nNode: #{node['fqdn']}"
  action :create
end
package 'nginx' { action :upgrade; notifies :restart, 'service[nginx]' }
service 'nginx' { action [:enable, :start] }
RUBY

chef-client --local-mode --run-list 'recipe[demo]' --cookbook-path /tmp/chef-test/cookbooks
chef-client --local-mode --run-list 'recipe[demo]' --cookbook-path /tmp/chef-test/cookbooks --json-attributes '{"demo":{"msg":"hello"}}'
```

### Practice 13: Compare Same Config in All Three Tools

**Puppet**:
```puppet
class profile::nginx_complete {
  user { 'webapp': ensure => present, uid => 2001, groups => ['www-data'], managehome => true }
  package { 'nginx': ensure => installed }
  file { '/etc/nginx/nginx.conf': content => template('profile/nginx.conf.erb'), require => Package['nginx'] }
  service { 'nginx': ensure => running, enable => true, subscribe => File['/etc/nginx/nginx.conf'] }
  package { 'ufw': ensure => installed }
  exec { 'allow-nginx': command => '/usr/sbin/ufw allow 80/tcp && /usr/sbin/ufw allow 443/tcp',
    unless => '/usr/sbin/ufw status | grep -q "80/tcp.*ALLOW"', require => Package['ufw'] }
}
```

**Salt**:
```yaml
webapp-user:
  user.present: [{ name: webapp, uid: 2001, groups: www-data, createhome: true }]
nginx-pkg:
  pkg.installed: [{ name: nginx }, { require: [{ user: webapp-user }] }]
nginx-conf:
  file.managed:
    - name: /etc/nginx/nginx.conf
    - source: salt://nginx_complete/files/nginx.conf
    - require:
      - pkg: nginx-pkg
nginx-service:
  service.running: [{ name: nginx, enable: true }, { watch: [{ file: nginx-conf }] }]
ufw-pkg: { pkg.installed: [{ name: ufw }] }
ufw-allow:
  cmd.run: [{ name: ufw allow 80/tcp && ufw allow 443/tcp },
    { unless: ufw status | grep -q "80/tcp.*ALLOW" }, { require: [{ pkg: ufw-pkg }] }]
```

**Chef**:
```ruby
user 'webapp' { uid 2001; groups ['www-data']; manage_home true; action :create }
package 'nginx' { action :install }
template '/etc/nginx/nginx.conf' { source 'nginx.conf.erb'; notifies :reload, 'service[nginx]' }
service 'nginx' { action [:enable, :start]; supports reload: true }
package 'ufw' { action :install }
execute 'ufw-allow-nginx' { command 'ufw allow 80/tcp && ufw allow 443/tcp'
  not_if 'ufw status | grep -q "80/tcp.*ALLOW"' }
```

**Ansible** (for comparison):
```yaml
- name: Configure web server
  hosts: all; become: true
  tasks:
    - user: { name: webapp, uid: 2001, groups: www-data, create_home: true }
    - apt:  { name: nginx, state: present }
    - template: { src: nginx.conf.j2, dest: /etc/nginx/nginx.conf }
      notify: reload nginx
    - service: { name: nginx, state: started, enabled: true }
    - ufw: { rule: allow, port: '{{ item }}', proto: tcp }
      loop: [80, 443]
  handlers:
    - name: reload nginx
      service: { name: nginx, state: reloaded }
```

### Practice 14: Use Test-Kitchen to Test on Multiple Platforms

```bash
chef generate cookbook myapp && cd myapp
```

**`kitchen.yml`**:
```yaml
driver: { name: vagrant }
provisioner: { name: chef_zero }
platforms:
  - name: ubuntu-22.04
  - name: ubuntu-20.04
  - name: centos-stream-9
suites:
  - name: default
    run_list: ["recipe[myapp::default]"]
```

```ruby
# test/integration/default/default_test.rb
control 'myapp-01' do
  describe package('myapp')   { it { should be_installed } }
  describe service('myapp')   { it { should be_running } }
  describe port(8080)         { it { should be_listening } }
end
```

```bash
kitchen test   # converge + verify + destroy on all platforms
```

### Practice 15: Real-World Integration — CM Strategy for 500 Servers

**Scenario**: Fintech with 500 servers across 3 DCs + AWS (200 web, 100 API, 50 DB, 50 cache, 50 MQ, 50 monitoring). PCI-DSS and SOC2 compliance. 6 SREs. Hybrid: 300 on-prem + 200 AWS.

**Recommended: Puppet Enterprise**

**Why**:
1. **Scale**: Handles 500 nodes easily (PE supports 10K+)
2. **Compliance**: Built-in reporting + PuppetDB = audit-ready history
3. **Data separation**: Hiera + hiera-eyaml for clear separation of global, env, node, and secret data
4. **Roles/Profiles**: Clean architecture for 8 server types
5. **PuppetDB search**: Query which nodes have specific package versions
6. **RBAC**: Enterprise console for team access control

**Architecture**:
```
Control Repo (GitLab) → r10k deploy → Puppet Enterprise
  3x Compile Masters (LB) + PuppetDB HA (Patroni)
  → Agents: 150 DC1 + 150 DC2 + 200 AWS
```

**Management Plan**:
- **Control repo**: `main` (prod), `staging`, `dev` branches. Puppetfile for modules.
- **Node classification**: Hiera-based (role + env keys). All nodes get `role::base`.
- **Change management**: MR → review → merge → webhook triggers r10k → staggered agent runs (5% canary → full).
- **Compliance**: CIS benchmarks via `puppetlabs/cis_benchmark`. All changes in PuppetDB.
- **HA**: 3 compile masters behind HAProxy. PuppetDB with Patroni PostgreSQL HA.
- **Migration to containers**: Phase 1 — Puppet manages base OS + Docker. Phase 2 — stateless apps to K8s. Phase 3 — Puppet only for stateful DBs + compliance.

---

## Deep Understanding

### How Puppet Compiles Catalogs

```
Facts → Puppet Server (HTTPS POST /puppet/v3/catalog)
  → site.pp node matching → Parser (Lexer → AST)
  → Evaluator (conditionals, loops, Hiera lookups)
  → Dependency resolver (require/before/notify/subscribe)
  → Compiler → Catalog (JSON DAG of resources + edges)
  → Signed with server cert → Agent
  → Walks DAG, per resource: provider checks state vs catalog
  → Out of sync → converge; in sync → skip → Report → PuppetDB
```

### How Salt's Event-Driven System Works

```
ZeroMQ PUB (4505): Master → All minions (job announcements)
ZeroMQ REQ/REP (4506): Master ↔ Minion (job results)
Event Bus (IPC): Every component publishes events → Reactor matches tags → SLS actions

Example: Minion detects disk >90% (beacon)
  → Publishes salt/beacon/diskusage/web01 event
  → Reactor matches pattern (salt/beacon/diskusage/*)
  → Runs reactor SLS: alert PagerDuty, migrate data
```

```python
# Any process can subscribe to event bus
import salt.config, salt.utils.event
opts = salt.config.client_config('/etc/salt/master')
event = salt.utils.event.get_event('master', opts, listen=True)
for e in event.iter_events():
    print(e['tag'], e['data'])
```

### How Chef's Search API Works

```
Recipe calls search(:node, 'role:web_server')
  → Chef Client → HTTPS GET /search/node?q=role:web_server
  → Chef Server → Queries Solr/Elasticsearch index
  → Index updated after every chef-client run (node object stored)
  → Returns array of partial node objects

Search syntax:
  search(:node, 'platform:ubuntu AND chef_environment:production')
  search(:node, 'fqdn:*.example.com')
  search(:node, 'role:web_server', filter_result: { 'ip' => ['ipaddress'] })
  search(:users, 'groups:admin')     # data bag search
```

### Resource Abstraction Layer

| Resource | Provider | OS Command |
|----------|----------|------------|
| Puppet `package` | `apt` provider | `apt-get install` |
| Puppet `package` | `yum` provider | `yum install` |
| Salt `pkg.installed` | `aptpkg` | `apt-get install` |
| Salt `pkg.installed` | `yumpkg` | `yum install` |
| Chef `package` | `apt` provider | `apt-get install` |
| Chef `service` | `systemd` provider | `systemctl start` |

Providers selected via `defaultfor :operatingsystem => :ubuntu` (Puppet), grains `os_family` (Salt), `provides :service, platform_family: 'debian'` (Chef).

### Convergence and Idempotency

**Puppet**: Each resource defines `insync?`. `file` checks stat (owner/group/mode/checksum). `package` checks `dpkg -l` / `rpm -q`. `service` checks `systemctl is-active`. If `insync?` → skip. `--noop` for dry-run.

**Salt**: State modules have `_check` (validate) and `_mod` (converge) methods. `pkg.installed`: checks pkg database, skips if version matches. `test=True` for dry-run.

**Chef**: `load_current_resource` loads state → compares with desired. `converge_by` blocks for idempotency. `--why-run` for dry-run.

---

## Command Reference

### Equivalent Concepts Across All Four Tools

| Concept | Puppet | Salt | Chef | Ansible |
|---------|--------|------|------|---------|
| Config file | `.pp` manifest | `.sls` state | `.rb` recipe | `.yml` playbook |
| Server | Puppet Server (JRuby) | Salt Master (Python) | Chef Server (Erlang) | None |
| Agent | `puppet agent` | `salt-minion` | `chef-client` | None (SSH) |
| System data | Facter → `$facts` | Grains → `grains` | Ohai → `node['...']` | `ansible_*` |
| Package | `package {'n': ensure}` | `pkg.installed` | `package 'n'` | `package:` |
| Service | `service {'n': ensure}` | `service.running` | `service 'n'` | `service:` |
| File | `file {'/p': content}` | `file.managed` | `file|template` | `copy|template` |
| User | `user {'n': ensure}` | `user.present` | `user 'n'` | `user:` |
| Execute | `exec {'c': command}` | `cmd.run` | `execute 'c'` | `command|shell` |
| Cron | `cron {'j': command}` | `cron.present` | `cron 'j'` | `cron:` |
| Dependencies | require/before/notify/subscribe | require/watch/onchanges | notifies/subscribes | when/notify |
| Dry run | `--noop` | `test=True` | `--why-run` | `--check` |
| Templates | ERB (`template()`), EPP (`epp()`) | Jinja | ERB | Jinja |
| Secrets | hiera-eyaml | GPG renderer, vault | encrypted data bags | ansible-vault |
| Module repo | Puppet Forge | SaltStack Formulas | Chef Supermarket | Ansible Galaxy |
| Dependency mgmt | Puppetfile + r10k | saltutil.sync_all + git | Berksfile + Berkshelf | requirements.yml |
| Testing | rspec-puppet, beaker | testinfra | ChefSpec, test-kitchen | molecule |
| Environments | env dir + r10k | top.sls + file_roots | env JSON db | inventory groups |
| Classification | site.pp + Hiera | top.sls | roles + environments | inventory |
| Orchestration | Bolt / Puppet Tasks | salt-run + reactor | knife ssh / push jobs | AWX/Tower |
| Event driven | No (polling) | Yes (ZeroMQ event bus) | No (polling) | No (push) |
| GUI | PE Console | SaltStack Enterprise | Chef Automate | AWX/Ansible Tower |

---

## What's Coming in Part 55

**Part 55: Immutable Infrastructure — Packer and Image Baking**

- Immutable vs mutable servers: philosophy and trade-offs
- Packer: builders (AMI, Docker, QEMU, vSphere), provisioners (shell, Ansible, Chef, Salt), post-processors
- Building golden AMIs with hardened CIS benchmarks
- Image pipelines: GitLab CI + Packer + Terraform = full GitOps
- Packer HCL2: variables, sources, builders, provisioners
- Golden image management: versioning, testing, promotion, rollback
- When to use Packer vs Ansible vs Terraform vs Dockerfile
- Real-world case study: baking 5000 AMIs/month

---

## Self-Test

1. What is the difference between declarative and procedural configuration management? Give one example of each.

2. Explain the resource abstraction layer in Puppet. How does `package { 'nginx': ensure => installed }` work differently on Ubuntu vs CentOS without changing the manifest?

3. Write a Puppet manifest that installs nginx, ensures the service is running, and deploys `/etc/nginx/nginx.conf` from an ERB template with `worker_processes = 4`. Include proper dependency ordering.

4. What is Hiera and how does it achieve data separation in Puppet? Write a `hiera.yaml` hierarchy with common, per-OS, and per-node data files.

5. In SaltStack, what is the difference between grains and pillars? When would you use each?

6. Write a Salt SLS file that creates user `deploy` (UID 2001), adds their SSH key, installs nginx, and ensures the service is running. Use `require` for ordering.

7. What is Salt's event bus and how does the reactor system work? Give an example of a reactor rule responding to a minion startup.

8. How does Chef's Search API work? Write a Ruby snippet using `search` to find all nodes with role `web_server` and generate nginx upstream configs for them.

9. Write a Chef recipe that: creates user `webapp` (UID 2001), installs nginx, deploys `/etc/nginx/nginx.conf` from template, enables/starts the service, and notifies on template changes.

10. What are the advantages and disadvantages of agentless (Ansible) vs agent-based (Puppet/Chef/Salt) configuration management?

11. Explain the Puppet catalog compilation process from facts submission to report delivery.

12. What is the roles and profiles pattern in Puppet? Why is it considered a best practice for large deployments?

13. Compare testing ecosystems: rspec-puppet vs test-kitchen/ChefSpec vs Salt's testing vs molecule. Which would you choose for a team of 6 SREs managing 500 servers?

14. Design a simple CM strategy for 50 servers (10 web, 5 DB, 5 cache, rest mixed). Choose a tool and justify based on architecture, team skills, and ops requirements.

15. How does the shift toward containers and immutable infrastructure affect traditional CM tools? What use cases remain where CM is still the best solution?

**Score:** 12/15 correct = ready for Part 55.

---

*Linux SysAdmin Course | Part 54 of ∞ | Reverse Engineering Approach*
*Previous → Part 53: CI/CD Pipelines*
*Next → Part 55: Immutable Infrastructure*

[← Previous](part53.md) | [Next →](part55.md)
