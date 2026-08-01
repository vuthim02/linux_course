## 📏 Rules of Thumb

### The Text Processing Rules

| Rule | Description | Why |
|------|-------------|-----|
| **Test before -i** | sed -i is permanent | Safety |
| **Use awk for columns** | Field processing | Efficiency |
| **Use sed for lines** | Line processing | Simplicity |
| **Use grep for filtering** | Pattern matching | Speed |
| **Chain commands** | Build pipelines | Composability |

---

**Why these rules matters:** Following these rules helps you build reliable text processing pipelines.

[← Previous](21-16-self-test.md) | [↑ Index](index.md)
