## Deep Understanding

### How the PAM Stack Actually Resolves

The key insight is that PAM processes control flags in a specific way:

```
auth  required   pam_a.so       → passes:  continue
auth  required   pam_b.so       → fails:   continue (but mark failure)
auth  sufficient pam_c.so       → skipped: (prior required failed)
auth  required   pam_d.so       → passes:  continue
auth  required   pam_deny.so    → always fails

RESULT: FAILURE (pam_b.so failed, "required" tracks the failure)
        Even though pam_a.so, pam_c.so, pam_d.so passed

KEY RULE: "sufficient" is only effective if NO prior "required" has failed.
```

```
auth  required   pam_a.so       → passes:  continue
auth  sufficient pam_b.so       → passes:  RETURN SUCCESS immediately
                                     (no prior required failed)
auth  required   pam_c.so       → never reached
auth  required   pam_deny.so    → never reached

RESULT: SUCCESS (pam_b.so succeeded as sufficient)
```

### The Complete Authentication Timeline

```
┌──────────────────────────────────────────────────────────┐
│  t=0ms    User enters username at login prompt            │
│  t=0ms    login process calls pam_authenticate("login")   │
│  t=1ms    PAM reads /etc/pam.d/login                      │
│  t=1ms    PAM loads pam_env.so → sets env variables        │
│  t=2ms    PAM loads pam_faillock.so preauth → checks lock  │
│  t=3ms    Account NOT locked → continue                    │
│  t=3ms    PAM loads pam_unix.so → prompts for password     │
│  t=5000ms User enters password                             │
│  t=5001ms pam_unix.so checks /etc/shadow → success/fail    │
│  t=5002ms If fail: pam_faillock.so authfail → increments   │
│  t=5003ms If fail: pam_deny.so → DENIED                   │
│  t=5003ms If success: pam_sss.so → forward to SSSD        │
│  t=5100ms SSSD checks cache → hit? return immediately     │
│  t=5100ms SSSD checks LDAP → queries server               │
│  t=5200ms LDAP returns success → SSSD returns to PAM      │
│  t=5201ms All required modules passed → AUTH GRANTED        │
│  t=5202ms pam_account checking → pam_unix, pam_sss         │
│  t=5203ms Account is valid → proceed                       │
│  t=5204ms pam_session setup → pam_limits, pam_namespace    │
│  t=5205ms Home directory created (pam_mkhomedir)           │
│  t=5206ms Shell launched                                   │
│  TOTAL: ~5.2 seconds (mostly user typing time)             │
└──────────────────────────────────────────────────────────┘
```

### SSSD Response Flow

```
┌─────────────────────────────────────────────────────────────┐
│  PAM request: "Authenticate user=john, password=***"         │
│                      │                                       │
│                      ▼                                       │
│  ┌───────────────────────────────────┐                      │
│  │  SSSD Monitor Process              │                      │
│  │  (receives request)                │                      │
│  └───────────────┬───────────────────┘                      │
│                  │                                            │
│          ┌───────┴────────┐                                  │
│          │                │                                   │
│    ┌─────▼──────┐  ┌─────▼──────────┐                       │
│    │ Cache Hit?  │  │ Cache Miss?     │                      │
│    │             │  │                  │                      │
│    │ Check ldb   │  │ Query LDAP/Kerb │                      │
│    │ database    │  │ Server           │                     │
│    └─────┬──────┘  └─────┬──────────┘                       │
│          │                │                                   │
│    ┌─────▼──────┐  ┌─────▼──────────┐                       │
│    │ Password   │  │ Password        │                      │
│    │ verified   │  │ verified by     │                       │
│    │ from cache │  │ LDAP/Kerb       │                       │
│    └─────┬──────┘  └─────┬──────────┘                       │
│          │                │                                   │
│          └────────┬───────┘                                  │
│                   │                                           │
│          ┌────────▼──────────┐                               │
│          │  Return to PAM:    │                              │
│          │  PAM_SUCCESS or    │                              │
│          │  PAM_AUTH_ERR      │                              │
│          └───────────────────┘                               │
└─────────────────────────────────────────────────────────────┘
```

### authselect vs Manual Editing Decision Tree

```
Need to modify PAM?
         │
         ▼
Does a feature exist for it?
         │
    ┌────┴────┐
    Yes       No
    │         │
    ▼         ▼
  Enable   Create custom profile
  feature  authselect create-profile
    │         │
    ▼         ▼
  authselect  Edit files in
  enable-    /etc/authselect/custom/
  feature    <profile>/
    │         │
    ▼         ▼
  authselect  authselect select
  apply-     custom/<profile>
  changes
```





[← Previous](11-hands-on-practices.md) | [↑ Index](index.md) | [Next →](13-command-reference.md)
