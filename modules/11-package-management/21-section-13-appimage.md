## Section 13: AppImage — Portable Self-Contained Apps

AppImage is a universal packaging format that requires no installation — just download and run.

```bash
# Download an AppImage
wget https://example.com/app.AppImage

# Make executable and run
chmod +x app.AppImage
./app.AppImage

# Integrate with system (optional)
./app.AppImage --install        # Add menu entry and icons

# Extract to inspect contents
./app.AppImage --appimage-extract
```

### Comparison: Snap vs Flatpak vs AppImage

| Feature | Snap | Flatpak | AppImage |
|---------|------|---------|----------|
| Sandboxing | Strong (AppArmor) | Strong (Bubblewrap) | None |
| Installation | `snap install` | `flatpak install` | Download + chmod |
| Updates | Automatic | Automatic | Manual |
| Central repo | Snap Store | Flathub | N/A (distributed) |
| Requires daemon | Yes (snapd) | Yes (flatpakd) | No |
