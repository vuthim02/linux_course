## 📏 Rules of Thumb

### The Module Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Use modprobe** | Not insmod | Handles dependencies |
| **Use modprobe -r** | Not rmmod | Handles dependencies |
| **Check dependencies** | Before removing | Prevent breakage |
| **Blacklist carefully** | Test first | Stability |

---

**Why these rules matters:** Following these rules prevents kernel panics and module-related issues.

[← Previous](16-self-test-can-you-answer-these.md) | [↑ Index](index.md)
