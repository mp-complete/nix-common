# nix-common

An opinionated, reusable **dendritic flake-parts configuration library**: NixOS/Home Manager feature buckets, explicit package wrappers, editor/tool configurations, and extensible agent tooling.

Extracted from `mp-complete/nixdots` at `75a7ef92dc874c0812f08beaf4eb619bc164ecba`, with fresh history and the same upstream dependency pins. Personal machines and credentials live in a separate consumer; work configuration can live under a different owner without either repository depending on it.

## Consume

```nix
{
  inputs = {
    common.url = "github:mp-complete/nix-common";
    nixpkgs.follows = "common/nixpkgs";
    flake-parts.follows = "common/flake-parts";
    import-tree.follows = "common/import-tree";
  };
  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.common.flakeModules.default
        (inputs.import-tree ./modules)
      ];
      username = "alice";
      git = {
        userName = "Alice Example";
        userEmail = "alice@example.com";
        forgejoUrls = [ ];
      };
      home.stateVersion = "24.11"; # use the existing machine's value
    };
}
```

Commit your own `flake.lock`. `common` is independently pinned by each consumer. Align Nixpkgs/Home Manager through `follows` rather than accidentally introducing multiple competing package sets. Pi and Noctalia deliberately retain their upstream-tested package sets; do not blanket-rewrite every transitive Nixpkgs input.

A file such as `modules/hosts/laptop.nix` can use the shared builder:

```nix
{ mkHost, ... }: {
  flake.nixosConfigurations.laptop = mkHost {
    buckets = [ "base" "hardware" "dev" "ai" "skills" ];
    modules = [
      ./_hardware.nix
      {
        networking.hostName = "laptop";
        system.stateVersion = "24.11";
        programs.nh.flake = "/home/alice/src/config";
      }
    ];
  };
}
```

Importing a bucket opts into its feature. `mkHost` pulls both its NixOS and Home Manager contributions into the consumer's primary user. Hardware/desktop selection, real filesystem configuration, compatibility versions and activation remain consumer responsibilities. The library does not deploy any machine on import.

## Extend without forking

Each file under a consumer's `modules/` is a flake-parts module. It can merge any existing bucket:

```nix
{
  flake.modules.homeManager.dev = { pkgs, ... }: {
    home.packages = [ pkgs.hello ];
  };
  flake.wrappers.tmux = { lib, ... }: {
    prefix = lib.mkForce "C-b";
  };
}
```

Wrappers remain explicit: `config.flake.wrappers.<name>.wrap { inherit pkgs; }`. There is no global wrapper overlay. The Pi registry is `pi.extensions`; wrapper extension lists and system prompt files can be extended using normal module merging.

For private/local skills, extend the registry and supply the source downstream:

```nix
{
  flake.modules.homeManager.skills = {
    skills.availableExtra = [ "team-review" ];
    skills.extra = [ "team-review" ];
    programs.agent-skills.sources.team.path = ./_skills;
  };
}
```

`skills.builtinExtra` adds always-selected consumer skills. Shared generic skills are retained; the original corporate warehouse review skill is not shipped. Common-owned dependency inputs are captured lexically by the pinned `import-tree.addScoped` facility. Shared **configuration** still evaluates inside the consumer's flake-parts graph, so downstream identities, bucket additions and wrapper changes are not frozen to producer defaults. Ordinary `inputs` in downstream NixOS/Home Manager modules refers to the consumer's inputs, including private ones.

## Secrets and service boundaries

Common contains **no encrypted credentials, recipient metadata, private endpoints, personal hosts, or private flake inputs**.

- `ai.secretSource = ./api-keys.enc.yaml` optionally binds consumer-owned SOPS YAML containing `github`. Default `null` permits normal interactive Copilot authentication without creating secret declarations or an `ai-env` template.
- Generic OpenClaw service buckets retain their process isolation/hardening. A node requires `services.openclaw-node.gatewayTokenFile`; a gateway requires flake-parts `openclaw.gatewayTokenFile`. These are runtime paths, never plaintext Nix strings. Consumers own provisioning, ownership/mode and restart behavior. Optional `openclaw.model` and `openclaw.publicUrl` have no personal defaults.
- Generic Atuin configuration remains shared; its encrypted sync key/binding is consumer-owned.
- Generic WSL integration remains shared; corporate GPG bootstrap/key delivery and work profiles remain downstream.
- Personal mounts, WireGuard declarations, SSH exposure and Forgejo runner provisioning remain consumer-owned.

Private repository visibility is not a Nix-store secrecy boundary. Never put credentials into derivations; choose builders/caches appropriate for private source.

## Standalone packages and validation

The producer uses the same reusable module with neutral example identity solely to expose packages/checks. Consume `flakeModules.default`, not producer-evaluated identity-bearing buckets.

```sh
nix build .#tmux --no-link
nix build .#pi-desktop --no-link
nix build .#nvim --no-link
bash tests/validate.sh --build
```

The validation script evaluates a **separate consumer flake** with a different identity, state version, extra input, custom skill source, and renamed wrapper. It also tests Copilot without configured credentials, evaluates flake outputs, runs local extension tests, and builds representative wrapper/daemon checks. It performs no activation and requires no work/personal credentials.

The example's relative input is overridden explicitly in the test script for compatibility with Nix 2.26 Git-subdirectory resolution. See [example/README.md](example/README.md) before copying the fixture as a real repository.

## Compatibility and provenance

This extraction intentionally does not upgrade dependencies, rewrite the architecture, or fix unrelated host choices. Unknown bucket names retain the original class-filtering behavior; consumers should review their lists. The original Laplace `sway` mismatch is documented in the personal consumer rather than silently changing its desktop.

See [EXTRACTION-NOTES.md](EXTRACTION-NOTES.md) for boundaries. No new license is asserted for copied source or bundled third-party assets; retained notices continue to apply. Public visibility is not a blanket relicensing grant.
