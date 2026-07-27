## How Cleanup Canonicalises Addresses

The `cleanup` daemon applies these transformations **before** queuing:

1. Adds `Received:` header with client info, protocol, timestamp
2. Applies canonical mappings (`canonical_maps`) — rewrite local parts
3. Applies sender/recipient canonical maps
4. Applies `masquerade_domains` — strip subdomains from sender addresses
5. Inserts `Message-ID:` if missing
6. Converts 8-bit MIME to 7-bit if needed
7. Adds `From`, `To`, `Date`, `Subject` if missing (from envelope)



---

[← Previous](57-how-the-queue-manager-sorts.md) | [↑ Index](index.md) | [Next →](59-smtp-protocol-state-machine.md)
