## 📏 Rules of Thumb

### The Production Script Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Always use set -euo pipefail** | Catch errors early | Reliability |
| **Always quote variables** | Prevent word splitting | Safety |
| **Always use functions** | Avoid repetition | Maintainability |
| **Always log** | Know what happened | Debugging |
| **Always test** | Verify before deploy | Stability |

### The Script Debugging Rules

```bash
# Check syntax:
bash -n script.sh

# Run with debug:
bash -x script.sh

# Add debug to script:
set -x    # Enable debug
set +x    # Disable debug
```

---

**Why these rules matters:** Following these rules ensures your scripts are reliable and maintainable.

[← Previous](22-17-self-test.md) | [↑ Index](index.md)
