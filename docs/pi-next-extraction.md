# pi-next extraction scope

## Common base

This introduces the reusable portion of the work deployment's current
`pi-next` implementation, including its in-progress extension integrations.
The initial extraction has been narrowed to a wrapper-only utility. Consumers
extend the shared wrapper and own installation. This update does not modify or
repin any work/personal checkout; their installation modules migrate separately.

| Component reviewed | Decision |
| --- | --- |
| Pi runtime, launcher-only package, self-update/offline defaults | Common; preserve the exact upstream input/runtime pins and legacy coexistence |
| `pi-next` wrapper/module API | Common; no standalone base package or installation buckets; consumers extend then install |
| Extension overlay | Private to the wrapper's package set; not exported or applied to a host |
| Eight pinned npm resource roots and dependency closure | Common; one extension module per resource under `modules/pi-next/extensions/`, all registered resources loaded, additive lists replaceable with `mkForce` |
| Official notifier | Common; selects its transport at runtime, does not require a WSL bucket |
| Exa MCP | Common, overridable defaults; public anonymous service, not a corporate integration; requests disclose queries/URLs to a third party |
| `mk-pi-extension` skill bundle | Common wrapper resource only; any global Home Manager skill installation is consumer-owned |
| Resource-loading, native-library, mocked-notification and coexistence checks | Common; baseline checks are producer-only, with a separate customized consumer check |
| Work-local install skill and `/add-pi-extension` prompt | Stay downstream; contain checkout-specific ownership and workflow instructions, not global Pi resources |
| Microsoft/private skills and work-specific validation | Stay downstream; no private source or reverse dependency is added |
| Work identity, `hilbert`/`msft`, WSL deployment, secrets/authentication | Stay downstream; no host, identity, state-version or credential migration |
| Extension research notes | Stay in the source checkout; this repository carries only curated integration/scope documentation |

## Composition boundaries

Common inputs are lexically captured with `builtins.scoped.commonInputs`, as
in the existing modules. Shared wrapper configuration remains unevaluated in
the consumer's flake-parts graph. Consumers define a wrapper under their own name
with `imports = [ common.wrapperModules.pi-next ];`, then explicitly install its
`.wrap { inherit pkgs; }` result. They can also extend/install directly through
`common.wrappers.pi-next.wrap`. Never set `package` to a built wrapper or replace
module registries with `//`.

Common excludes the base from automatic package outputs, supplies no Pi-next
NixOS/Home Manager buckets, and does not extend the global `skills` bucket with
Pi-specific sources. The extension overlay applies only inside wrapper evaluation.
This deliberately changes the initial extraction's installation API; see the
migration section in `pi-next.md`.

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

- Build the four baseline `pi-next*` checks and `pi-next-api`, which rejects
  standalone base packages, installation buckets and public overlay exports.
- Evaluate the separate `example#consumerContract` and build its
  `checks.x86_64-linux.consumer-pi`, with the local common input override shown
  in `tests/validate.sh`. The fixture declares no Pi/skills dependency inputs
  and derives a wrapper with its own name, explicit skill, prompt and MCP policy.
  It installs through its own bucket, retains common resources inside the wrapper,
  and rejects Pi-specific global skill sources/selections.
- Run the source-boundary check and `nix flake check --no-build`.
- No activation, provider inference, delegated jobs, live PTYs, browser reviews,
  authentication helpers or real notification delivery are part of validation.

## Validation results

Validated on x86_64-linux after narrowing the public API to the wrapper utility:

- All four baseline `pi-next*` checks and the new `pi-next-api` check passed.
- `bash tests/validate.sh --build` passed: source boundaries, independent consumer
  contract, flake evaluation, existing local extension tests, consumer wrapper
  builds, and the legacy Pi-agent/Edge bootstrap build checks.
- The customized consumer loaded its own skill and prompt, used its renamed XDG
  profile, registered no MCP servers, and retained the common skill and
  extensions, including Plannotator.
- Nix formatting and Git whitespace checks passed. No input, runtime or extension
  pins changed in this wrapper-only update.

Builds may reuse valid local/cache outputs. No full host activation or interactive
behavior is claimed; the integration notes list the remaining runtime limits.
