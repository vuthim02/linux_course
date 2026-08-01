## ✅ Section 18: Self-Test

**Instructions:** Answer each question. Score 12/15 or higher before proceeding to Part 42.

### Questions

**Q1:** What does LDAP stand for, and what is its primary purpose?

**Q2:** What is the difference between a DN and an RDN? Give an example.

**Q3:** Write the LDIF to add a user `uid=charlie,ou=People,dc=example,dc=com` with objectClass `inetOrgPerson` and `posixAccount`. Charlie Brown, uid=10003, gid=10003, /home/charlie, /bin/bash.

**Q4:** What is the OLC (Online Configuration) in OpenLDAP, and why is it preferred over editing slapd.conf?

**Q5:** You run `ldapsearch -x -b dc=example,dc=com '(uid=alice)'` and get "No such object (32)." What are the three most likely causes?

**Q6:** What is the difference between PAM and NSS? Which controls authentication and which controls lookups?

**Q7:** You installed `libnss-ldapd` on a client but `getent passwd alice` returns nothing. List three debugging steps.

**Q8:** What does the `-ZZ` flag in `ldapsearch -ZZ` do?

**Q9:** In Kerberos, what is a TGT? What is the difference between the AS and the TGS?

**Q10:** What is SSSD and what advantage does it have over direct PAM LDAP (`libpam-ldapd`)?

**Q11:** What is the difference between `type=refreshAndPersist` and `type=refreshOnly` in OpenLDAP replication?

**Q12:** FreeIPA combines which four major components?

**Q13:** An LDAP Bind Request fails with result code 49. What does this mean? How would you troubleshoot?

**Q14:** What is the `memberOf` overlay and why would you use it?

**Q15:** In the PAM auth stack, what is the difference between `required` and `sufficient`?

### Answer Key

**A1:** Lightweight Directory Access Protocol. Directory service for centralized user/group storage, address books, authentication, and configuration.

**A2:** DN is the full path (e.g. `uid=alice,ou=People,dc=example,dc=com`). RDN is the local component (e.g. `uid=alice`). The RDN is the first component of the DN.

**A3:**
```ldif
dn: uid=charlie,ou=People,dc=example,dc=com
objectClass: inetOrgPerson
objectClass: posixAccount
cn: Charlie Brown
sn: Brown
uid: charlie
uidNumber: 10003
gidNumber: 10003
homeDirectory: /home/charlie
loginShell: /bin/bash
```

**A4:** OLC stores config as LDAP entries under `cn=config`, modifiable with `ldapmodify` while slapd runs. Preferred because: no restart needed, validated on load, can be replicated, version-controlled via LDIF.

**A5:** (1) Wrong base DN — `dc=example,dc=com` does not exist on server. (2) No permissions — anonymous bind not allowed to search. (3) Server unreachable — wrong host/port, firewall blocking 389.

**A6:** **PAM** controls authentication (password verification, account expiry, session setup). **NSS** controls lookups (`getent passwd`, `getent group`, etc.). PAM authenticates; NSS retrieves identity data.

**A7:** (1) Check `nslcd` is running: `systemctl status nslcd`. (2) Check `/etc/nsswitch.conf` has `ldap` in `passwd` line. (3) Test connectivity: `ldapsearch -x -H ldap://server -b dc=example,dc=com '(uid=alice)'`.

**A8:** Require StartTLS — the client will refuse to connect if the server does not upgrade to TLS. Single `-Z` means "try TLS but proceed without if unavailable."

**A9:** **TGT** (Ticket Granting Ticket) is a ticket proving the user authenticated successfully. **AS** (Authentication Service) issues TGTs after verifying password. **TGS** (Ticket Granting Service) issues service tickets using the TGT.

**A10:** SSSD caches credentials locally, allowing offline authentication (network goes down but users still log in). It also provides faster responses (cache hit vs. network query) and supports multiple identity providers.

**A11:** `refreshAndPersist` — consumer pulls full data, then stays connected for real-time updates. `refreshOnly` — consumer polls periodically (no persistent connection, higher latency).

**A12:** 389 Directory Server (LDAP) + MIT Kerberos + BIND (DNS) + Dogtag Certificate System (CA) + NTP.

**A13:** **Invalid Credentials** — the bind DN or password is wrong. Troubleshoot: (1) Verify the DN is correct (`dn:` in LDIF matches). (2) Check the password with `slappasswd -v`. (3) Test with `ldapwhoami -x -D ... -W`. (4) Check server logs: `journalctl -u slapd`.

**A14:** The memberOf overlay automatically populates a `memberOf` attribute on user entries listing which groups they belong to. Without it, you must search groups for `memberUid=alice`. It makes "what groups is alice in?" a single lookup instead of a subtree search.

**A15:** `required` — module must succeed; if it fails, continue checking other modules but deny at end. `sufficient` — if module succeeds, immediately accept authentication (skip remaining modules). If it fails, continue checking.

### Scoring

| Score | Result |
|-------|--------|
| **15/15** | Perfect — you are ready for DNS administration |
| **12–14/15** | Strong understanding — proceed to Part 42 |
| **9–11/15** | Review the sections you missed — you are close |
| **< 9/15** | Re-read Part 41 and practice with the 15 hands-on exercises |

**Score:** ___/15 correct = ready for Part 42.





[← Previous](21-section-17-whats-coming-in.md) | [↑ Index](index.md) | [Next →](23-quick-reference-cards.md)
