# agent-browser-edge-bridge

Pi extension for the WSL wrapper. It makes `pi-chrome-use` Edge-only: before
any `browser_execute` call runs, the bridge starts or verifies a dedicated
Microsoft Edge profile on Windows and installs its WSL-reachable browser
WebSocket endpoint as `BU_CDP_WS`.

Authentication remains in Windows Edge. The bridge never exports cookies,
tokens, or profile data into WSL, and the CDP WebSocket URL is kept in the Pi
process environment rather than added to the model-visible tool input.

## Usage

There is no public/work backend selector. Public web research stays with
`pi-web-access`; interactive browser automation always targets the dedicated
Windows Edge profile.

A first `browser_execute` snippet connects through the bridge-provided endpoint:

```js
await session.connect();
const { targetInfos } = await session.Target.getTargets({});
return targetInfos.filter((target) => target.type === "page");
```

Later `browser_execute` calls in the same Pi session reuse `pi-chrome-use`'s
persistent CDP session. If Edge is closed or restarted, the bridge revalidates
and re-establishes the endpoint before the next browser call; the snippet may
need to call `session.connect()` again after a disconnected WebSocket.

Every browser call verifies the reachable endpoint against the exact Edge
browser identity established on Windows. Ambient `BU_CDP_WS` and `BU_CDP_URL`
values are cleared when the extension loads, so this wrapper cannot silently
fall back to an unrelated browser endpoint.

## Windows Edge bootstrap

On the first browser call, `scripts/bootstrap.sh`:

1. Checks WSL interop and the effective registry value for Edge
   `RemoteDebuggingAllowed`. Explicit `0` is a policy failure; absent means
   remote debugging is allowed by Edge policy.
2. Resolves Edge from Windows App Paths, Program Files, or PATH.
3. Starts a visible Edge instance with a non-default persistent profile at:

   ```text
   %LOCALAPPDATA%\Microsoft\Edge\User Data - CDP
   ```

4. Verifies port 9222 is owned by that Edge executable, is bound only to
   Windows loopback, and has exactly one matching remote-debugging-port and
   dedicated-profile argument.
5. Probes `127.0.0.1:9222` from WSL first. This is the preferred mirrored-
   networking path and needs no relay.
6. Under WSL NAT only, starts `cdp_forwarder.ps1` bound to the specific Windows
   gateway address (never `0.0.0.0`) and forwards to Windows localhost:9222.
7. Requires every WSL-reachable `/json/version` response to match the exact
   browser product and browser WebSocket identity verified on Windows localhost.

The TypeScript bridge keeps the verified `/devtools/browser/<id>` path but
rewrites the host to the exact HTTP endpoint that WSL proved reachable. This is
necessary because Edge may report a Windows-loopback WebSocket URL that is not
reachable from a NAT-mode WSL guest.

An existing port listener is never killed or silently reused. Edge and
forwarder listeners must have the expected executable, command line, profile,
ports, and bind address; otherwise bootstrap reports a layer-specific collision.
Every Pi runtime re-runs these ownership checks instead of trusting a cached URL.

### Repeatable script staging

Before invoking PowerShell, bootstrap stages the controller and forwarder under
content-derived names in Windows TEMP. Existing files are reused only when they
are owned by the WSL user, regular files (not symlinks), and byte-identical to the
packaged sources. This supports old read-only cached copies without rewriting
or chmodding them: Nix-store sources are mode `0444`, which plain `cp` propagates
to a newly created destination and cannot overwrite on the next run.

New scripts are copied into private mode-`0600` temporary files, then published
with exclusive hard-link creation. A concurrent bootstrap can only reuse a
verified winner. `mv -n` is deliberately not used: concurrent publication showed
transient missing destinations on DrvFS. The Windows TEMP filesystem must
support hard links and meaningful ownership metadata; the tested WSL mount uses
DrvFS metadata. There is no fallback to copying into the final path.

Unexpected paths, contents, or staging failures stop before PowerShell with a
`Windows TEMP staging` diagnostic. Inspect the named path and permissions rather
than blindly deleting caches or changing Windows policy. Ordinary failures clean
up the caller's staging file; SIGKILL/power loss can leave a `.pi-edge-stage.*.ps1`
name, possibly another link to a published script. This is not protection against
malicious same-user mutation, nor a lease on the browser itself.

### Optional environment overrides

- `WSL_BROWSER_DEBUG_PORT` (default `9222`)
- `WSL_BROWSER_FORWARD_PORT` (default `9223`)
- `WSL_BROWSER_USER_DATA_DIR` (Windows path)
- `WSL_BROWSER_EDGE_EXE` (Windows path to `msedge.exe`)

`BU_CDP_WS` and `BU_CDP_URL` are bridge-owned in this wrapper and are not caller
overrides.

## Commands

- `/ab-edge-status` shows the Edge-only backend, verified browser identity,
  reachable HTTP endpoint, environment state, and any bootstrap cooldown.
- `/ab-edge-reset` forgets in-memory bridge state and clears the bridge-owned
  CDP environment. It does **not** stop Edge, PowerShell, or any listener. The
  next `browser_execute` call performs a complete revalidation.

## Policy and security notes

- The dedicated profile keeps automation separate from the user's primary Edge
  profile while retaining Windows authentication and device-compliance flows.
- CDP grants complete control of that profile. The NAT relay remains limited to
  the Windows gateway interface visible to WSL; do not expose its ports through
  firewall, portproxy, LAN, VPN, or container forwarding rules.
- `pi-chrome-use` intentionally executes model-authored JavaScript and permits
  dynamic Node imports. This is not a sandbox; use the same trust boundary as
  Pi's normal coding tools.
- This slice does not implement cross-worker leases. Do not give concurrent
  autonomous workers unmanaged control of the same Edge profile.

## Validation

From this extension directory, `npm test` runs the local suite. From the
nix-common root, run the packaged check and wrapper build:

```bash
nix build --no-link .#checks.x86_64-linux.edge-cdp-bootstrap .#pi-wsl
```

The packaged check runs Bash syntax validation, ShellCheck (excluding SC2015 for
the existing intentional port guards), and all non-live tests. The eleven
bootstrap regressions execute the actual shell script with Windows commands and
CDP stubbed, including read-only cached scripts, 32 concurrent starts, rejected
unexpected paths, partial-copy cleanup, and missing hard-link support. They run
on Linux without Windows, a browser, credentials, or an agent process. To test
DrvFS behavior, set `TMPDIR` to a writable mounted Windows temp directory and run
`node --test test/bootstrap.test.mjs`; fixtures clean up after themselves.

The startup integration test is skipped unless `PI_TEST_BINARY` points to an
unwrapped Pi executable. For an explicitly requested manual loader check, from
the nix-common root:

```bash
PI_TEST_BINARY=/absolute/path/to/unwrapped/pi \
  node --test modules/ai/extensions/_local/agent-browser-edge-bridge/test/startup.test.mjs
```

This launches Pi in an isolated directory without credentials or model calls
and checks that the bridge's commands register. It does not start Edge.

The Nix extension derivation and `pi-wsl` wrapper are the authoritative
packaging checks. Live validation should confirm a visible dedicated Edge
window, an `Edg/*` `/json/version` response, an accepted WebSocket connection,
existing login continuity, manual MFA/Hello interaction, and no credential
export into WSL.
