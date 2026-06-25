Good — this is exactly the kind of situation where Linux looks “error-heavy” but most issues come from **driver + firmware mismatch after switching from Windows**.

I’ll give you a **complete, practical fix plan**, grouped by your actual errors.

---

# 🧠 BIG PICTURE (what happened)

You moved from Windows → Linux on hardware that likely has:

* NVIDIA GPU (nouveau driver is unstable)
* Intel audio DSP (needs firmware packages)
* Mixed laptop/desktop ACPI + power management quirks
* Some services not fully configured on first install

So we fix it in **layers**:

---

# 🔴 1. FIX NVIDIA / GPU PROBLEMS (MOST IMPORTANT)

Your logs:

```text
nouveau ... RT_HEIGHT_OVERRUN
```

This means: ❌ open-source NVIDIA driver is unstable on your GPU

---

## ✅ Solution A (BEST): Install proprietary NVIDIA driver

### Step 1: Check GPU

```bash
lspci | grep -E "VGA|3D"
```

If you see NVIDIA → continue.

---

### Step 2: Enable RPM Fusion (Fedora official extra repo)

```bash
sudo dnf install \
https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

sudo dnf install \
https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

---

### Step 3: Install NVIDIA driver

```bash
sudo dnf update -y
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
```

---

### Step 4: Rebuild kernel module

```bash
sudo akmods --force
sudo dracut --force
```

---

### Step 5: Reboot

```bash
reboot
```

---

### Step 6: Verify

```bash
nvidia-smi
```

If it shows GPU info → FIXED ✔

---

## 🚫 Disable nouveau (important)

Edit:

```bash
sudo nano /etc/default/grub
```

Add:

```text
rd.driver.blacklist=nouveau modprobe.blacklist=nouveau
```

Then:

```bash
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

---

# 🟠 2. FIX AUDIO (Intel SOF / AVS errors)

Your error:

```text
snd_soc_avs ... topology failed -2
```

This means missing firmware.

---

## ✅ Install full audio firmware stack

```bash
sudo dnf install linux-firmware alsa-sof-firmware sof-firmware
```

---

## Restart audio system

```bash
systemctl --user restart pipewire
systemctl --user restart wireplumber
```

---

## Check sound devices

```bash
pactl list short sinks
```

---

## If still broken

Force reload:

```bash
sudo alsa force-reload
```

---

# 🟡 3. FIX BLUETOOTH ISSUE

Error:

```text
bluetoothd: Failed to set default system config
```

---

## Fix steps

```bash
sudo dnf install bluez bluez-tools
sudo systemctl enable --now bluetooth
```

---

## Check device blocked?

```bash
rfkill list
```

If blocked:

```bash
sudo rfkill unblock bluetooth
```

---

# 🟠 4. FIX D-BUS SERVICE FAILURES

Errors:

* UPower
* Avahi
* GeoClue
* ColorManager

---

## Install missing system services

```bash
sudo dnf install \
upower avahi geoclue2 colord NetworkManager
```

---

## Enable services

```bash
sudo systemctl enable --now upower
sudo systemctl enable --now avahi-daemon
sudo systemctl enable --now geoclue
```

---

# 🟡 5. FIX FIREWALL + DOCKER CONFLICT

Error:

```text
docker-forwarding NAME_CONFLICT
```

---

## Reset firewalld docker rules

```bash
sudo firewall-cmd --permanent --remove-zone=docker
sudo firewall-cmd --reload
```

---

## Restart Docker

```bash
sudo systemctl restart docker
```

---

# 🟡 6. FIX PCIe AER ERRORS

These:

```text
pcieport AER: Error of this Agent
```

Usually caused by power management.

---

## Fix kernel parameters

Edit GRUB:

```bash
sudo nano /etc/default/grub
```

Add:

```text
pcie_aspm=off
```

Then:

```bash
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg
```

---

# 🟡 7. FIX KEYRING WARNING

Error:

```text
gkr-pam unable to locate daemon
```

---

## Fix GNOME keyring

```bash
sudo dnf install gnome-keyring
```

---

# 🧠 8. CLEAN SYSTEM CHECK (IMPORTANT STEP)

After all fixes:

## Check broken services

```bash
systemctl --failed
```

---

## Check boot errors again

```bash
journalctl -b -1 -p err
```

---

## Check performance

```bash
systemd-analyze blame
```

---

# 🧪 FINAL STATE YOU WANT

After fixing everything:

You should see:

```bash
journalctl -b -1 -p err
```

→ EMPTY or near-empty

---

# 🚨 PRIORITY ORDER (VERY IMPORTANT)

Do this in order:

1. 🔴 NVIDIA driver fix (MOST IMPORTANT)
2. 🟠 Audio firmware fix
3. 🟡 D-Bus service fixes
4. 🟡 Bluetooth fix
5. 🟡 Firewalld/docker cleanup
6. 🟡 PCIe tuning (optional)
7. 🟡 Keyring fix

---

# 💡 REALITY CHECK

Nothing here indicates your system is broken.

What you have is:

> A perfectly normal Linux migration state from Windows hardware → missing proprietary drivers + firmware gaps

---

# If you want next step

I can help you upgrade this into a **fully optimized Linux system**:

* zero boot errors
* stable NVIDIA performance
* gaming-ready setup
* low-latency audio
* faster boot time analysis

Just tell me 👍
