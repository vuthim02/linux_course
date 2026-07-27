## 4. Installing Podman

```bash
# Ubuntu / Debian
sudo apt update
sudo apt install podman podman-compose

# Verify
podman --version
podman info
```

### Configuration Files

Podman uses plain text config files under `~/.config/containers/`:

```toml
# ~/.config/containers/registries.conf
unqualified-search-registries = ["docker.io", "quay.io"]

[[registry]]
location = "docker.io"
[[registry.mirror]]
location = "mirror.gcr.io"

[[registry]]
location = "192.168.1.100:5000"
insecure = true
```

```toml
# ~/.config/containers/storage.conf
[storage]
driver = "overlay"
runroot = "/run/user/1000/containers"
graphroot = "/home/user/.local/share/containers/storage"

[storage.options]
size = ""
```

```toml
# ~/.config/containers/containers.conf
[containers]
env = ["LANG=en_US.UTF-8"]

[engine]
runtime = "crun"
events_logger = "file"
```

### System-wide configs

```
/etc/containers/registries.conf
/etc/containers/storage.conf
/etc/containers/containers.conf
~/.config/containers/registries.conf.d/*.conf
```

---



---

[← Previous](06-3-installing-docker.md) | [↑ Index](index.md) | [Next →](08-5-images.md)
