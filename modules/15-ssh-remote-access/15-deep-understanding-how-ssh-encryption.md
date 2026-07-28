## 🧠 Deep Understanding — How SSH Encryption Works

### Symmetric vs Asymmetric Encryption

```
SSH uses BOTH:

1. Asymmetric (public key) — for key exchange and authentication
   - Server has private host key
   - You see the public host key on first connect
   - Used to establish a secure channel

2. Symmetric (shared secret) — for the actual session
   - Both sides derive the same session key
   - Much faster than asymmetric
   - Used for ALL data during the session
```

### The Key Exchange (Diffie-Hellman)

```
1. Client and server agree on a large prime number p and generator g
2. Client picks secret a, sends A = g^a mod p
3. Server picks secret b, sends B = g^b mod p
4. Client computes: K = B^a mod p = g^(a*b) mod p
5. Server computes: K = A^b mod p = g^(a*b) mod p
6. Both now have the SAME session key K
7. Even if attacker captures A and B, they cannot compute K
   (discrete logarithm problem — computationally infeasible)
```

### Perfect Forward Secrecy

Modern SSH uses ephemeral Diffie-Hellman — a NEW key pair is generated for each session. Even if the server's long-term private key is stolen later, past sessions cannot be decrypted.

### SSH Agent Protocol

```
ssh-agent stores your decrypted private key in memory.
When you authenticate:

1. Server sends challenge (random data encrypted with your public key)
2. SSH client asks agent: "Please decrypt this"
3. Agent decrypts with private key (held in memory)
4. SSH client sends decrypted challenge back to server
5. Server verifies → authenticated

The private key NEVER leaves the agent.
```





[← Previous](14-practice-section-15-hands-on-exercises.md) | [↑ Index](index.md) | [Next →](16-summary-complete-command-reference-for.md)
