# pi-next extraction scope

## Common base

This introduces the reusable portion of the work deployment's current
`pi-next` implementation, including its in-progress extension integrations.
It is an introduction in common, not a simultaneous consumer cutover.
The work checkout and its staged/unstaged changes are left intact; a follow-up
can replace its duplicate definitions with extensions of this shared wrapper.

| Component reviewed | Decision |
| --- | --- |
| Pi runtime, launcher-only package, self-update/offline defaults | Common; preserve the exact upstream input/runtime pins and legacy coexistence |
| `pi-next` wrapper and standalone Home Manager/NixOS buckets | Common; host selection remains downstream |
| Eight pinned npm resource roots and dependency closure | Common; one extension module per resource under `modules/pi-next/extensions/`, all registered resources loaded, additive lists replaceable with `mkForce` |
| Official notifier | Common; selects its transport at runtime, does not require a WSL bucket |
| Exa MCP | Common, overridable defaults; public anonymous service, not a corporate integration; requests disclose queries/URLs to a third party |
| `mk-pi-extension` skill bundle and shared skills source | Common; source stays in the pinned upstream input, no copied skill implementation |
| Resource-loading, native-library, mocked-notification and coexistence checks | Common; baseline checks are producer-only, with a separate customized consumer check |
| Work-local install skill and `/add-pi-extension` prompt | Stay downstream; contain checkout-specific ownership and workflow instructions, not global Pi resources |
| Microsoft/private skills and work-specific validation | Stay downstream; no private source or reverse dependency is added |
| Work identity, `hilbert`/`msft`, WSL deployment, secrets/authentication | Stay downstream; no host, identity, state-version or credential migration |
| Extension research notes | Stay in the source checkout; this repository carries only curated integration/scope documentation |

## Composition boundaries

Common inputs are lexically captured with `builtins.scoped.commonInputs`, as
in the existing modules. Shared wrapper configuration remains unevaluated in
the consumer's flake-parts graph. The future work layer should extend
`flake.wrappers.pi-next` after importing `common.flakeModules.default`, not set
`package` to the built common wrapper or replace module registries with `//`.
A separately named package can use `common.wrappers.pi-next.wrap` directly.

The original `pi-next` executable/profile defaults are unchanged. Renamed
wrappers now default to their own `${XDG_CONFIG_HOME:-$HOME/.config}/<binName>`
directory rather than accidentally sharing `pi-next`. Consumers can explicitly
retain a previous directory. Environment overrides and ambient project/user
resources are still honored, so this is not a security isolation boundary.

Exa's URL, description and exposure are `mkDefault` values. Disable all declared
MCP services with `mcpServers = lib.mkForce { };` or disable Exa with
`mcpServers.exa.enabled = false;`. Nix offline mode is not an extension network
sandbox. Plannotator's optional sharing/AI/browser actions and interactive shell
execution still require the operator's own policy; see the integration notes.

Only x86_64-linux is a supported/check-exercised output of this repository.
Native PTY loading is tested without opening terminals. Do not infer Darwin or
other architecture support from upstream prebuilds.

## Validation contract

- Build `packages.x86_64-linux.pi-next` and the four `pi-next*` baseline checks.
- Evaluate the separate `example#consumerContract` and build its
  `checks.x86_64-linux.consumer-pi`, with the local common input override shown
  in `tests/validate.sh`. The fixture declares no Pi/skills dependency inputs
  and extends the base with its own name, explicit skill, prompt and MCP policy
  while retaining the common resources.
- Run the source-boundary check and `nix flake check --no-build`.
- No activation, provider inference, delegated jobs, live PTYs, browser reviews,
  authentication helpers or real notification delivery are part of validation.

## Validation results

Validated on x86_64-linux after the per-extension registry split and removal of
per-entry enable switches:

- `packages.x86_64-linux.pi-next` and all four baseline `pi-next*` checks passed.
- `bash tests/validate.sh --build` passed: source boundaries, independent consumer
  contract, flake evaluation, existing local extension tests, consumer wrapper
  builds, and the legacy Pi-agent/Edge bootstrap build checks.
- The customized consumer loaded its own skill and prompt, used its renamed XDG
  profile, registered no MCP servers, and retained the common skill and
  extensions, including Plannotator.
- Nix formatting and Git whitespace checks passed. Existing common input pins
  were unchanged; the added Pi dependency graph matches the work source pins.

Builds may reuse valid local/cache outputs. No full host activation or interactive
behavior is claimed; the integration notes list the remaining runtime limits.
