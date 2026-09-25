# Extraction boundaries

Baseline: `mp-complete/nixdots` at `75a7ef92dc874c0812f08beaf4eb619bc164ecba`. Only tracked source files were considered. No original Git history, memory/bootstrap files, decrypted secrets, or environment state was copied.

## Common

Reusable feature implementations, packages and assets remain together so relative imports continue to work. Existing themes, wallpapers, shell/editor opinions, generic Azure DevOps tooling and the `miles.bb` helper namespace are retained as configuration preferences, not account bindings.

Minimal decoupling:

- Export the import tree as `flakeModules.default`, using `import-tree.addScoped` to bind common-owned dependencies. `builtins.scoped.commonInputs` is provided by that pinned import-tree implementation; it is not a standard Nix builtin.
- Evaluate feature configuration inside each consumer's module graph. Forward consumer `inputs` to its NixOS/Home Manager modules.
- Require consumer username/Git identity and make Home Manager compatibility version configurable.
- Replace embedded AI ciphertext with nullable `ai.secretSource`; make the Copilot wrapper work without an `ai-env` secret template.
- Allow downstream skill registries/selections; use the common-owned Matt Pocock source path directly rather than requiring a consumer input by that name.
- Keep generic Atuin configuration, but not the secret-bound sync slice.
- Template Noctalia wallpaper paths with the actual home directory.
- Remove personal Nix registry and hardcoded remote nixd configuration expressions. The editor remains otherwise unchanged.
- Keep generic OpenClaw gateway/node services with consumer-provisioned runtime token paths and no personal model/URL defaults.
- Replace the personal Pi daemon example/check with synthetic common test jobs. Runtime scripts and hardening remain shared.

## Personal consumer

`nix-personal` owns:

- Euler and Laplace host files, hardware, EDIDs and monitor placement.
- Personal username, Git identity/Forgejo endpoints, checkout path and registry.
- `network/{mounts,samba,syncthing,wireguard}.nix`, SSH exposure, Forgejo runner provisioning.
- Personal encrypted files, SOPS creation rules and AI/Atuin secret bindings.
- The disabled historical documentation-maintenance job, still targeting the old repository.
- New personal evaluation/regression CI, rather than old host-specific Forgejo workflows.

Existing mixed SOPS documents are handled only in the private consumer; see its README for the byte-preserving ciphertext limitation. They are never included here.

## Retained only in the original source for later work migration

- Work hosts `general2`, `hilbert`, `nixos`.
- `modules/work/**`.
- Fabric shell aspect and Trident warehouse dev-shell profile.
- `warehouse-ux-pr-review` skill and its source assets.
- The corporate MCP overlay (`overlays/agent-mcps`) with internal endpoint/tenant bindings; it is not a generic public overlay.
- Work WSL GPG key/bootstrap and gateway-token deployment bindings.

Generic WSL/public vendor tooling is not treated as corporate configuration merely because the original work machines selected it.

## Deliberately unchanged

- The original repository and its lockfile.
- Upstream input revisions (common starts with the exact baseline lockfile).
- Explicit wrapper design and dendritic feature buckets.
- Host hardware and state versions.
- `mkHost` ignoring names absent from both class registries, including the pre-existing Laplace `sway` mismatch. This migration does not invent a Sway configuration.

Historical proposals, stale wrapper docs and old Forgejo workflows were not blindly republished as current documentation. The original repository retains them for reference. No new license or third-party ownership claim was introduced.
