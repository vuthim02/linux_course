## 🔍 Section 4: Setting Variables

### Temporary (Session Only)

```bash
# In the current shell
export MY_VAR="hello"
MY_VAR="hello"  # Without export — only shell-local, not passed to children

# For one command only
MY_VAR="hello" mycommand

# Remove a variable
unset MY_VAR
```

### Per-User Permanent (~/.bash_profile or ~/.profile)

```bash
# Add to ~/.bash_profile
echo 'export EDITOR=nano' >> ~/.bash_profile
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bash_profile

# Apply to current session
source ~/.bash_profile
```

### System-Wide Permanent (/etc/profile or /etc/environment)

```bash
# Method 1: /etc/profile (shell scripts, bash syntax)
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk' | sudo tee -a /etc/profile

# Method 2: /etc/environment (simple KEY=VALUE format, no export needed)
echo 'JAVA_HOME=/usr/lib/jvm/java-11-openjdk' | sudo tee -a /etc/environment

# Method 3: /etc/profile.d/ script (preferred for packages)
sudo tee /etc/profile.d/java.sh << 'EOF'
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
EOF
sudo chmod +x /etc/profile.d/java.sh
```

---



---

[← Previous](06-section-3-shell-startup-files.md) | [↑ Index](index.md) | [Next →](08-section-5-aliases.md)
