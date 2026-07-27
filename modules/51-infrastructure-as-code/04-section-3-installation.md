## 🔍 Section 3: Installation

### Installing Terraform on Ubuntu/Debian

```bash
# Add HashiCorp's official repository
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install
sudo apt update && sudo apt install -y terraform

# Verify
terraform --version
```

### Shell Autocomplete

```bash
# Install autocomplete (adds to ~/.bashrc or ~/.zshrc)
terraform -install-autocomplete

# Reload shell
exec $SHELL
```

Now you can type `terraform p` + Tab and get `plan`, `providers`, `push`, etc.

### Configuration File: .terraformrc

Terraform's CLI configuration lives at `~/.terraformrc`:

```hcl
# ~/.terraformrc
provider_installation {
  filesystem_mirror {
    path    = "/usr/share/terraform/providers"
    include = ["hashicorp/*"]
  }
  direct {
    exclude = ["hashicorp/*"]
  }
}
```

### Provider Plugin Caching

Downloading provider plugins on every `init` is slow. Enable caching:

```bash
# Option 1: Environment variable
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"

# Option 2: In .terraformrc
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
```

```bash
# Create the cache directory
mkdir -p ~/.terraform.d/plugin-cache
```

Now `terraform init` reuses cached plugins instead of downloading them fresh.

---



---

[← Previous](03-section-2-terraform-overview.md) | [↑ Index](index.md) | [Next →](05-section-4-core-concepts.md)
