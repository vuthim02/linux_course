## 📏 Rules of Thumb

### The LDAP Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use LDAPS** | Not plain LDAP | Security |
| **Use SSSD** | Not nslcd | Modern, cached |
| **Test with getent** | Verify resolution | Debugging |
| **Document schema** | Know your structure | Maintainability |

---

**Why these rules matters:** Following these rules ensures secure and reliable centralized authentication.

[← Previous](24-section-18-self-test.md) | [↑ Index](index.md)
