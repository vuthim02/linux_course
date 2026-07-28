## 6. SaltStack Architecture

### Core Components

```
                   ┌──────────────────────────┐
                   │     Salt Master           │
                   │  Port 4505 (ZMQ pub)      │
                   │  Port 4506 (ZMQ req/rep)  │
                   │  Event bus (ZMQ)         │
                   └──────┬──────────┬────────┘
                          │          │
                   ZMQ pub/sub   ZMQ req/rep
                          │          │
            ┌─────────────┼──────────┼──────────┐
            │             │          │          │
     ┌──────▼──────┐ ┌───▼────┐ ┌───▼────┐ ┌───▼────┐
     │  Minion 1   │ │ Minion2│ │ Minion3│ │...500  │
     └─────────────┘ └────────┘ └────────┘ └────────┘
```

1. **Salt Master**: Python. Port 4505 (publish bus — all minions subscribe), 4506 (request/response). Manages keys, pillars, file server.
2. **Minion**: Python daemon `salt-minion`. Subscribes to 4505, sends results via 4506.
3. **ZeroMQ**: Async message transport. Pub/sub (master → all) + request/response (master ↔ minion).
4. **Event Bus**: All components publish events. Reactor listens and fires actions.
5. **Minion Keys**: RSA key pairs. Accepted via `salt-key -A`.

### Key Management

```bash
salt-key -L          # List all keys
salt-key -a web01    # Accept a key
salt-key -A          # Accept all unaccepted
salt-key -d web01    # Delete
```





[← Previous](05-5-puppet-in-practice-roles.md) | [↑ Index](index.md) | [Next →](07-7-saltstack-states.md)
