## 🔍 Section 3: Redirecting stdin — The `<` Operator

Read input from a file instead of the keyboard.

```bash
# Count words in a file
wc -w < myfile.txt

# Sort lines from a file
sort < unsorted.txt

# Count lines in a file
wc -l < /etc/passwd
```

### When Would You Use `<`?

Most commands accept a filename as an argument:

```bash
# These do the same thing:
wc -l /etc/passwd
wc -l < /etc/passwd
```

But stdin redirection becomes powerful in pipelines (which we cover next). And some programs only read from stdin:

```bash
# Some commands only read from stdin (they don't accept filename arguments)
tr ',' '\n' < data.csv
# tr (translate) does not take a filename — you must redirect

mail -s "Subject" user@example.com < report.txt
# mail command reads the message body from stdin
```





[← Previous](03-section-2-redirecting-stdout-the.md) | [↑ Index](index.md) | [Next →](05-section-4-pipes-the-heart.md)
