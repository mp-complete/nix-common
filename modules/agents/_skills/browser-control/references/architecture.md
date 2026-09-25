# Architecture: WSL → Windows Edge over CDP

```
┌──────────────────────────────────────────────────────────────────────────┐
│ Windows                                                                  │
│                                                                          │
│   ┌──────────────────────────────────┐                                   │
│   │ Microsoft Edge                   │                                   │
│   │   profile: "User Data - CDP"     │ ← isolated from the user's main   │
│   │   --remote-debugging-port=9222   │   browsing profile                │
│   │   listens on 127.0.0.1:9222 only │                                   │
│   └────────────────┬─────────────────┘                                   │
│                    │ CDP (HTTP + WebSocket)                              │
│                    ▼                                                     │
│   ┌──────────────────────────────────┐                                   │
│   │ cdp_forwarder.py (python.exe)    │ ← stdlib-only TCP relay launched  │
│   │   listens 0.0.0.0:9223           │   via powershell.exe Start-Process │
│   │   forwards -> 127.0.0.1:9222     │                                   │
│   └────────────────┬─────────────────┘                                   │
└────────────────────┼─────────────────────────────────────────────────────┘
                     │ TCP over Hyper-V vEthernet (default-route IP)
┌────────────────────▼─────────────────────────────────────────────────────┐
│ WSL2                                                                     │
│                                                                          │
│   Playwright (Python or any CDP client)                                  │
│     chromium.connect_over_cdp("http://<win-host>:9223")                  │
│                                                                          │
│   <win-host> = `ip route show default | awk '/default/ {print $3}'`      │
└──────────────────────────────────────────────────────────────────────────┘
```

## Why each piece exists

### Dedicated Edge profile (`User Data - CDP`)

The user's regular Edge windows stay completely isolated:

- Their normal tabs, history, and extensions are untouched.
- The CDP profile keeps auth cookies between bootstrap runs, so users
  sign in once per service rather than every session.
- We can close/reopen this profile freely without affecting their work.

### `--remote-debugging-port=9222` only — no `--remote-debugging-address`

Modern Chromium binds the CDP port to `127.0.0.1` only and *ignores*
the `--remote-debugging-address` flag (it was removed circa 2023 as a
DNS-rebinding mitigation). We don't fight this — we bridge it.

### Windows-side TCP forwarder

Edge listens on Windows `127.0.0.1`. WSL2 in default NAT mode **cannot
reach Windows-`localhost`** directly — only services bound to a
non-loopback Windows interface. The forwarder binds `0.0.0.0:9223` (so
WSL can reach it via the Hyper-V vEthernet bridge IP) and forwards
bytes to `127.0.0.1:9222`.

We use Python because:

- The user already has a `python.exe` on Windows.
- The forwarder is ~50 lines of stdlib (no install step).
- The alternative, `netsh interface portproxy`, requires admin.

We launch it via `powershell.exe Start-Process` rather than
`cmd.exe /c start` because the latter chokes on a WSL working directory
(UNC path warnings) and on quote-escaping when invoked through bash.

### `chromium.connect_over_cdp`, not `chromium.launch`

The user's auth lives in the *Windows* Edge profile. A normal Playwright
`launch()` would spin up its own headless Chromium under Linux with no
cookies. `connect_over_cdp` attaches to the existing Edge so we drive
the user's authenticated session.

We grab `browser.contexts[0]` — Edge's default context, which owns all
the user's tabs and cookies. New pages opened in this context inherit
the active session.

### Default-route IP, not hard-coded subnet

`ip route show default` reliably gives the Windows host IP from inside
WSL2. The `172.x.x.x` subnet is **not** stable — Hyper-V re-rolls it
across Windows reboots — so we never hard-code it.
