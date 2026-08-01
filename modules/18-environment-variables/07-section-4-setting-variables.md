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

### System-Wide Permanent

#### Method 1: /etc/profile (shell scripts, bash syntax)
```bash
echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk' | sudo tee -a /etc/profile
```

#### Method 2: /etc/environment (PAM-level, no export needed)
Read by `pam_env` module — affects all PAM-authenticated sessions (login, SSH, display manager). Simple KEY=VALUE only, no shell expansion:
```bash
echo 'JAVA_HOME=/usr/lib/jvm/java-11-openjdk' | sudo tee -a /etc/environment
```

#### Method 3: /etc/profile.d/ script (preferred for packages)
```bash
sudo tee /etc/profile.d/java.sh << 'EOF'
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH="$JAVA_HOME/bin:$PATH"
EOF
sudo chmod +x /etc/profile.d/java.sh
```

#### Method 4: /etc/security/pam_env.conf (advanced PAM)
Supports `@{HOME}` and `${VAR}` expansion:
```
# /etc/security/pam_env.conf
XDG_CONFIG_HOME   DEFAULT=@{HOME}/.config
GOPATH            DEFAULT=${XDG_DATA_HOME}/go
```

#### Method 5: systemd environment.d (user services/graphical)
For systemd user services, Wayland sessions, and GDM:
```
# ~/.config/environment.d/envvars.conf
EDITOR=nano
BROWSER=firefox
```





[← Previous](06-section-3-shell-startup-files.md) | [↑ Index](index.md) | [Next →](08-section-5-aliases.md)
