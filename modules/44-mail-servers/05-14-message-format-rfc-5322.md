## 1.4 Message Format (RFC 5322)

```
Received: from mail.example.com (…)
  by mx.example.org (Postfix) with ESMTP id ABC123
  for <recipient@example.org>; Wed, 24 Jun 2026 10:00:00 +0000
From: Alice <alice@example.com>
To: Bob <bob@example.org>
Subject: Meeting at 3pm
Date: Wed, 24 Jun 2026 09:55:00 +0000
Message-ID: <20260624095500.ABCD@example.com>
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8

Bob,

See you in the conference room.

Best,
Alice
```

Each `Received:` header is added by every MTA that handles the message — invaluable for tracing.


# 2. Postfix Architecture




[← Previous](04-13-envelope-vs-header-vs.md) | [↑ Index](index.md) | [Next →](06-21-process-model-pre-fork.md)
