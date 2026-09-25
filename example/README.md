# Independent consumer fixture

This is a separate flake, not an already-evaluated producer module. It verifies:

- A different username, Git identity and Home Manager state version.
- Consumer-owned inputs reaching both NixOS and Home Manager modules.
- Downstream contributions to shared buckets and skill sources/selections.
- Copilot enabled with no SOPS ciphertext/template.
- A downstream rename of the shared tmux wrapper, exercised by a build check.

Run it from the common repository root with `bash tests/validate.sh --build`. Explicit local input overrides avoid Nix 2.26's relative-path ambiguity when evaluating a flake inside a Git subdirectory. The fixture has no separately committed lockfile; its common dependency's committed lock preserves upstream versions.

For a real work/personal repository:

1. Use `github:mp-complete/nix-common` instead of `path:..`.
2. Remove the synthetic `consumer-data` input, `consumerContract`, fixture host and test-only wrapper rename.
3. Add your own `import-tree ./modules`, hardware/hosts, identity and any private inputs.
4. Generate and commit that repository's own `flake.lock`.

The fixture is never activated. Its stateVersion values are test data, not an instruction to upgrade a real machine's compatibility version.
