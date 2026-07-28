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





[← Previous](02-2-puppet-architecture.md) | [↑ Index](index.md) | [Next →](04-4-puppet-modules-and-forge.md)
