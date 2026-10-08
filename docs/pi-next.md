# pi-next integration

## Baseline

`modules/pi-next/pi.nix` exposes a **wrapper utility**, not an installation
feature. Use `wrappers.pi-next` (`.wrap` / `.apply`) or the unevaluated
`wrapperModules.pi-next` to derive a consumer-owned wrapper, then install that
result explicitly. Common supplies no `pi-next` Home Manager/NixOS bucket,
standalone `packages.<system>.pi-next`, or public Pi-next overlay. It does not
add Pi-specific sources to the global `skills` bucket. The base does not depend
on `pi.enable`, desktop or WSL configuration.

The wrapper imports `pi-nix-wrapper.wrapperModules.pi` and explicitly chooses
its pinned pi-nix Node runtime (currently Pi 1.0.0). It does not change the
Numtide runtime or configuration used by the existing `pi` wrappers.

Only the upstream runtime's `bin` directory is exposed to the wrapper. Its
launcher uses absolute Nix-store paths for the runtime and libraries, so they
remain available without exporting a second `lib/node_modules` tree. This lets
legacy `pi` and `pi-next` coexist in Home Manager without file collisions or
relaxing collision checks.

The wrapper keeps upstream runtime defaults and adds declared resources:

- Binary: `pi-next`; no additional `bin/pi`.
- Agent directory: `${XDG_CONFIG_HOME:-$HOME/.config}/pi-next`.
- Settings, authentication, trust and sessions start fresh; no migration.
  MCP starts with the declarative Exa server below; no legacy servers migrate.
- The legacy extension registry, extra tool packages and wrapper prompt are
  not imported. Native MCP, codemode, tool-search and llama.cpp remain available
  according to Pi's defaults.
- `mk-pi-extension` is explicitly loaded from an `agent-skills-nix` bundle
  sourced from the pinned wrapper input. It works without activation or ambient
  skill discovery; supporting references remain alongside `SKILL.md`. This does
  not install the skill globally through Home Manager.
- Ambient discovery remains enabled, including shared `~/.agents/skills` and
  project resources. A fresh wrapper does not mean a hermetic project.
- Upstream's offline default and self-update protection remain unchanged.

## Customization

Consumers own both their derived wrapper and the installation decision. For
example, after importing `common.flakeModules.default`, define a consumer module:

```nix
{ config, inputs, ... }:
{
  flake.wrappers.pi-work = { pkgs, ... }: {
    imports = [ inputs.common.wrapperModules.pi-next ];
    binName = "pi-work";
    tools.packages = [ pkgs.ripgrep pkgs.jq ];
    skills = [ ./skills/review ];
  };

  flake.modules.homeManager.work-pi = { pkgs, ... }: {
    home.packages = [ (config.flake.wrappers.pi-work.wrap { inherit pkgs; }) ];
  };
}
```

Select the **consumer-defined** `"work-pi"` bucket in a host's `mkHost` call.
The wrapper framework also exposes the derived `packages.<system>.pi-work`;
common excludes only its base `pi-next` from automatic package outputs.
No default Pi-next package or installation is introduced by importing common.

The default `configDir` follows `binName`: renaming the executable to `pi-work`
selects `${XDG_CONFIG_HOME:-$HOME/.config}/pi-work`. Override `configDir` explicitly
when retaining an existing profile. Ambient discovery and caller environment
variables still take precedence as described below.

Resource lists compose additively. Replace a selection with `lib.mkForce` when
needed, rather than setting `package` to an already-built wrapper executable:

```nix
# Extend the consumer-owned wrapper above:
{
  flake.wrappers.pi-work = { lib, ... }: {
    mcpServers = lib.mkForce { }; # No declared remote services.
    # piPackages = lib.mkForce [ ]; # Optional: remove bundled npm resources.
  };
}
```

For direct use from a consumer's Home Manager module (without a new flake
wrapper declaration), extend and install in one expression:

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [ (inputs.common.wrappers.pi-next.wrap {
    inherit pkgs;
    binName = "pi-review";
    tools.packages = [ pkgs.jq ];
  }) ];
}
```

Both routes re-evaluate the module graph, not a nested shell launcher.
Common-owned dependencies are captured through `builtins.scoped.commonInputs`;
consumers do not need to declare a `pi-nix-wrapper` or `agent-skills` input.

### Migrating from the installation bucket

Remove reliance on common's `"pi-next"` bucket and define your own wrapper and
installation module as above. Keep `binName = "pi-next"` and the existing
`configDir` if retaining the current executable and state directory; the flake
wrapper attribute can still have a consumer-specific name. State versions and
mutable profile files need no migration.

If a consumer separately needs `mk-pi-extension` under `~/.agents/skills`, it must
own that Home Manager source/selection explicitly. The wrapper itself still
loads the bundled skill. Tests that previously used
`overlays.pi-next-extensions` can inspect the wrapper-local package set through
`(common.wrappers.pi-next.apply { inherit pkgs; }).pkgs.piExtensions`.

## Exa search MCP

`modules/pi-next/pi.nix` declares `mcpServers.exa` using Exa's hosted endpoint,
`https://mcp.exa.ai/mcp`. It uses native MCP with `codemode` exposure: search
and webpage-fetching tools are discovered and called through codemode, rather
than always adding their schemas to the model's tool list. No npm MCP adapter
or local server process is installed.

[Exa's documentation](https://github.com/exa-labs/exa-mcp-server#authentication)
describes anonymous access with rate limits. No API key is required for this
configuration. Queries and requested URLs are sent to Exa; do not send private
work content without appropriate approval.

After installing the rebuilt wrapper, use `/mcp` **inside `pi-next`** to inspect
Exa or sign in for higher limits. Shell `pi-next mcp list/login` cannot see this
extension-registered server. No authentication or live search is performed by
the checks. A same-name entry in the agent directory's `mcp.json` overrides the
registration; `/mcp` changes to the declarative entry last only for the session.

## Installing extensions

Use the bundled `/skill:mk-pi-extension` guidance for packaging constraints.
The work checkout's install skill and prompt are not global wrapper resources
and are intentionally not copied here. Add common resources declaratively;
never use mutable `pi install` as the implementation of a Nix change.

The registry lives in `modules/pi-next/extensions/`:

- `module.nix` defines `pi-next.extensions`, assembles the additive package
  overlay, and loads every registered resource in the wrapper.
- Each extension has its own flake-parts module (for example `plannotator.nix`)
  declaring `pi-next.extensions.<name>.build = pkgs: ...`.
  `kind = "extension"` selects a single file rather than a package.
- `_npm-source.nix` is the internal complete-root packaging helper, and
  `_rpiv-config.nix` is the shared RPIV dependency. Underscore-prefixed helpers
  are excluded from import-tree's module discovery.
- `plannotator-dependencies.json` sits beside `plannotator.nix` and retains its
  exact tarball pins and dependency links.

Registration includes the resource in the common wrapper; there are no
per-entry enable switches. Consumers can add registry entries as flake-parts
settings, outside `flake.wrappers.pi-next`. The exported `.wrap` interface
supports replacing `piPackages` or `extensions` with `lib.mkForce` without
changing the registry. Entries load in name order; all previous package pins
are retained.

The current package pins are:

| Package | Version | Resources |
| --- | --- | --- |
| `pi-powerline-footer` | 0.19.1 | Powerline footer extension |
| `pi-btw` | 0.7.1 | Side-conversation extension and `btw` skill |
| `awesome-pi-themes` | 1.2.19 | Theme collection and `look-pack` extension |
| `pi-subagents` | 0.76.1 | Delegation extension, two skills, and six workflow prompts |
| `pi-interactive-shell` | 0.17.0 | PTY shell tool, spawn/attach/dismiss commands, and `pi-interactive-shell` skill |
| `@juicesharp/rpiv-ask-user-question` | 2.12.0 | Structured `ask_user_question` tool |
| `@juicesharp/rpiv-todo` | 2.12.0 | `todo` tool, `/todos` command and task widget above the editor |
| `@plannotator/pi-extension` | 0.28.7 | Local plan/diff/Markdown review UI, four commands, and user-invoked skill |

These load as complete npm source roots through `piPackages`, retaining the
original package manifests and relative file layout. Relocating their
entrypoints through `mkPiExtension` plus `mkPiPackage` broke sibling imports in
Pi's loader; the smoke build reproduces that failure and passes with complete
roots. Keep `mkPiExtension` for self-contained entrypoints that do not depend on
sibling paths.

`pi-subagents` keeps its compiled source, built-in agent definitions, skills,
workflow prompts, and docs together. Its runtime dependency closure is pinned
without installer/lifecycle execution: `acorn` 8.18.0, `jiti` 2.7.0, `undici`
8.10.2, `yaml` 2.8.3, and `@js-temporal/polyfill` 0.5.1 with `jsbi` 4.3.2.
Pi-provided peers are not installed privately. These pins meet the declared
runtime ranges, including undici's Node >=22.19.0 requirement with the wrapper's
Node 24 runtime. The smoke build checks tool/command/skill/prompt registration,
not actual delegation, background runners, worktrees, or interactive UI.

`pi-interactive-shell` retains its TypeScript sources and skill in one package
root. Its pinned runtime closure is `re2js` 2.8.6, `@typesafe-ai/sdk` 0.6.0,
`@xterm/headless` 5.5.0, `@xterm/addon-serialize` 0.13.0, and `zigpty` 0.1.6.
The serializer's non-Pi peer `@xterm/xterm` is pinned to 5.5.0 too; Pi peers
remain host-provided. All packages ship loadable code; no lifecycle scripts,
Zig compiler, or mutable npm installation are used. `zigpty`'s `^0.1.6` range
excludes 0.2.x. On Linux, the selected x86_64/aarch64 N-API prebuild is patched
with a Nix glibc RPATH while retaining its package-relative location. The smoke
check imports it in the actual Pi runtime and requires `hasNative == true`,
because zigpty otherwise silently tolerates a failed native load.

The shell tool is active by default; `/spawn`, `/attach`, and `/dismiss` are
available after installing the rebuilt wrapper. No processes start merely from
registration. Keep agent delegation in `pi-subagents`; this addition does not
configure another orchestrator. Upstream `/spawn` defaults to the `pi` command
on PATH, which may be the legacy profile here, not `pi-next`. No spawn command
mapping is changed by this integration. Jev/TypeSafe transmission stays off by
upstream default; no credentials or opt-in settings are supplied. User config
is read from the selected agent directory's `interactive-shell.json`, and the
extension also reads `<cwd>/.pi/interactive-shell.json`. Its launch policy is
not a sandbox. For long quiet builds, disable dispatch quiet auto-close and
require actual process-exit evidence before reporting success. Linux/WSL
interactive PTYs, cancellation, overlays and monitoring remain untested;
validation only loads resources and the native library, without opening a PTY.

### Official completion notifications

`pi-notify-official` selects the official single-file
`packages/coding-agent/examples/extensions/notify.ts` from the **same locked
source as Pi 1.0.0**, through the `pi-notify-official.nix` registry entry. There is
no third-party `pi-notify` npm package, copied implementation, new dependency,
or separate version pin. Future Pi input updates also update this example.
It registers `agent_settled`, not `agent_end`, so retries, compaction and queued
continuations can finish before it announces “Ready for input.” This is main
session readiness, not proof all detached subagents have completed.

Upstream chooses Windows Terminal/WSL PowerShell toasts when `WT_SESSION` is
set, Kitty OSC 99 when `KITTY_WINDOW_ID` is set, otherwise OSC 777. Toasts need
`powershell.exe` on PATH and enabled Windows notifications; OSC behavior depends
on the terminal. No transport, sound, authentication or Windows settings are
changed here. The dedicated `pi-next-notify` build test captures all output and
mocks PowerShell, checking registration and all three transport branches without
sending real notifications. Actual desktop delivery remains untested.

### Structured questions

`@juicesharp/rpiv-ask-user-question` keeps its full TypeScript/module/resource
layout and pins `@juicesharp/rpiv-config` 2.12.0. Its Pi and TypeBox peers remain
host-provided. The optional `rpiv-i18n` peer is deliberately absent; English
fallback works without adding the separate language extension. Config is read
from the package's XDG configuration path, not written by this integration.
The upstream tool is hidden before non-UI agent turns and available with UI;
RPC uses host dialogs. The smoke command runs before that turn hook, so its
registration snapshot still contains the active tool. Separately, the probe
loads the lazy questionnaire graph and tests visibility reconciliation with a
fake API; it never opens a questionnaire, rings the terminal, or calls a model.

### Task tracking

`@juicesharp/rpiv-todo` 2.12.0 reuses the pinned `@juicesharp/rpiv-config` 2.12.0
dependency and host-provided Pi/TypeBox peers. The optional localization peer
stays omitted, matching the questionnaire. It adds the `todo` tool and `/todos`,
with an above-editor widget that appears when tasks exist. Powerline is not
replaced. Upstream defaults include a 12-content-row budget and a Ctrl+Shift+T
collapse shortcut; this integration changes neither. Real terminal shortcut
delivery and widget rendering remain untested.

Task snapshots replay from session history across reload/compaction. This is
separate from Plannotator's checklist; its `pi-todos` file-based integration is
for another package, not `rpiv-todo`. No automatic synchronization is configured.
The smoke check verifies tool/command registration and loads the lazy overlay
module without creating tasks or opening a widget.

### Plannotator

`@plannotator/pi-extension` retains its published HTML assets, generated server
sources and `skills/plannotator` directory. Its larger runtime closure is pinned
in `modules/pi-next/extensions/plannotator-dependencies.json`: 72 exact npm tarballs with
published integrity hashes and per-package dependency links, including required
non-Pi peers. The data is consumed by the same `npmSource` helper; no npm install
or lifecycle hook runs. Optional peer accelerators and optional external AI SDKs
are not installed. Linux `node-pty` 1.1.0 has no published prebuild, so its N-API
module is compiled directly with Nix C++, Node headers and node-addon-api 7.1.1;
other platforms retain their published prebuilds. The actual Pi smoke probe
loads node-pty without spawning a terminal. Only x86_64-linux has been checked.

Commands are `/plannotator-plan-mode`, `/plannotator-review`,
`/plannotator-annotate`, and `/plannotator-last`. Its knowledge skill is
user-invoked via `/skill:plannotator`; it is not advertised to the model. Idle
sessions keep the submit-plan/mark-done tools inactive, and the optional generic
`plannotator` agent tool remains off. Browser reviews, Windows launch behavior,
external AI providers and agent terminals are not exercised by the checks.

Plan mode is **not a sandbox**: the published handler gates built-in write/edit
to Markdown paths, not bash or arbitrary extension tools. Local Git review works
without assuming ADO remote-PR support. Upstream browser views can make release
checks, and optional AI, URL-fetching, sharing and agent-terminal features have
additional network/process effects. This integration does not enable optional
AI features or change upstream sharing settings; do not send work content to
unapproved services or assume all browser actions are offline.

`pi-background-tasks` is not included. The smoke check rejects its `bg`/`tasks`
commands and `bg_*`/`fusion_*` tools. The separate `pi-subagents` extension
remains enabled, including its `bg_wait` tool.

## Wrapper gaps and boundaries

Pinned to [pi-nix-wrapper at 0cc27df](https://github.com/mp-complete/pi-nix-wrapper/tree/0cc27df701b6a595c498969bd481f41df88d6aa9), preserving the source deployment's runtime and dependency pins.
None blocks this minimal integration; these matter when building it out later.

1. **Isolation is a default, not enforcement.** An inherited
   `PI_CODING_AGENT_DIR` overrides `configDir`; an inherited session-directory
   variable can redirect sessions too. Unset these when launching an independent
   profile from another Pi process. Ambient project resources remain shared,
   and third-party extensions may hard-code settings outside Pi's agent
   directory. No `HOME` rewriting is attempted.
2. **The npm extension helper does not build dependencies.** `mkPiExtension`
   extracts a tarball and exposes a single entrypoint. Dependencies must be
   bundled or built separately. To retain a package's skills, prompts and
   themes, pass a complete package root through `piPackages`, not only the
   entrypoint helper. The declared multi-file packages here use complete source
   roots; do not relocate their entrypoints. The old registry is intentionally
   not imported here.
3. **Declarative MCP servers are invisible to shell subcommands.**
   `mcpServers` generates a registration extension. It loads in sessions, not
   `pi-next mcp list/login`; manage those servers through `/mcp` in a session.
   Store no literal secrets in Nix; use runtime interpolation or OAuth.
4. **Resources do not automatically propagate into third-party subagents.**
   `pi-subagents` 0.76.1 uses in-process SDK sessions for foreground children
   and a detached Node runner for npm-backed background children. Parent wrapper
   flags are not a child resource configuration; select child extensions and
   skills explicitly when needed. Leave `PI_SUBAGENT_PI_BINARY` unset for the
   normal runtime. Its override affects project panes/model probes (and
   binary-backed hosts), not npm background-runner selection. Do not point it
   at the full wrapper: injected explicit extensions could bypass a child's
   restricted extension selection. Child execution remains untested here.
5. **Offline startup is broader than suppressing update notices.** It also
   suppresses automatic model-catalog refresh and missing-package installation.
   Set `offline = false` to opt in; an inherited `PI_OFFLINE` still takes
   precedence, and setting it to `0` is not a reliable override in all Pi paths.
6. **Existing session-picker discovery is not fully XDG-aware.** The normal
   `~/.config/pi-next` location is found by the legacy picker; a custom
   `XDG_CONFIG_HOME` or session directory is not automatically searched.

## Validation

`checks.x86_64-linux.pi-next-api` asserts that only the wrapper/module APIs are
exported for Pi-next: no base package, installation buckets or public overlay.
The independent consumer also checks that global skills have no Pi-specific
source or selection.

`checks.x86_64-linux.pi-next` builds the base through `.wrap`'s module evaluation
and tests explicit installation in a standalone Home Manager fixture without
`ai`, base, desktop or WSL modules. That test environment also includes
the legacy `pi-wsl` package; `checks.x86_64-linux.pi-next-coexistence` builds its
actual Home Manager package environment to catch collisions between the two
runtimes. The `pi-next` smoke check runs the real binary in a disposable HOME,
checking native resources, absence of legacy tools/prompts/skills, default
and overridden config paths (including spaces), package/MCP subcommand dispatch,
and blocked self-updates. It also checks the generated Exa registration while
same-name disabled entries in disposable agent directories prevent remote
connections. It checks interactive-shell command/tool/skill registration and
native zigpty loading without spawning a shell, monitor or agent. It makes no
model calls and uses no real credentials. It also checks the official notifier's
wrapper selection, questionnaire lazy loading/visibility, Plannotator assets and
commands, and native node-pty loading. It never launches a review browser.

`checks.x86_64-linux.pi-next-notify` runs the official source in an isolated JS
context with fake environment/stdout/process-launch functions. It asserts
settled-only registration and the OSC 777, OSC 99 and Windows-toast payloads.

`checks.x86_64-linux.pi-next-skills` independently verifies the declared
`mk-pi-extension` skill with a fresh HOME and `--no-skills`. It disables the
declared npm package list, explicit notification extension and MCP servers for
this check only, to isolate skill loading and avoid remote connections.

Run `nix build .#checks.x86_64-linux.pi-next-skills --no-link` for the skill check
or `nix build .#checks.x86_64-linux.pi-next --no-link` for the full wrapper.
Run `nix build .#checks.x86_64-linux.pi-next-notify --no-link` for mocked notification tests.
For untracked dependency/test files, use `path:$PWD` in place of `.` until they
are tracked; no staging or activation is necessary for those builds.
Run `nix build .#checks.x86_64-linux.pi-next-coexistence --no-link` to check that
both Pi packages can be installed together.
The implementation and its input pin are owned by nix-common. Consumers extend
the wrapper and own installation; no host selections are made here.
The baseline checks in `tests/pi-next/checks.nix` are producer-only, so consumers
can change resources or rename the executable without inheriting hard-coded
baseline test expectations. The separate `example` consumer imports the exported
wrapper module under its own name, installs it via its own Home Manager bucket,
and checks inherited resources, profile isolation and the explicitly bundled
skill without any global Pi skill source or extra dependency inputs.
Interactive login, authenticated MCP, provider inference and full host builds
are outside these checks.
