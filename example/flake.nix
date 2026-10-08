{
  inputs = {
    nix-common.url = "path:..";
    nixpkgs.follows = "nix-common/nixpkgs";
    flake-parts.follows = "nix-common/flake-parts";
    import-tree.follows = "nix-common/import-tree";
    consumer-data = {
      url = "path:./fixture-data";
      flake = false;
    };
  };
  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      {
        config,
        lib,
        mkHost,
        ...
      }:
      {
        imports = [ inputs.nix-common.flakeModules.default ];
        username = "consumer";
        git = {
          userName = "Independent Consumer";
          userEmail = "consumer@example.invalid";
          forgejoUrls = [ ];
        };
        home.stateVersion = "24.11";

        # Extend an existing shared bucket in the consumer, not the producer.
        flake.modules.nixos.base = { inputs, ... }: {
          environment.variables.CONSUMER_MARKER = builtins.readFile (inputs.consumer-data + "/marker");
        };
        flake.modules.homeManager.base = { inputs, ... }: {
          home.sessionVariables.CONSUMER_MARKER = builtins.readFile (inputs.consumer-data + "/marker");
        };
        flake.modules.homeManager.skills = { inputs, ... }: {
          skills.availableExtra = [ "consumer-skill" ];
          skills.extra = [ "consumer-skill" ];
          programs.agent-skills.sources.consumer.path = inputs.consumer-data + "/skills";
        };
        flake.wrappers.tmux.binName = "consumer-tmux";
        # Own both the derived wrapper and its installation bucket downstream.
        flake.wrappers.consumer-pi = { lib, ... }: {
          imports = [ inputs.nix-common.wrapperModules.pi-next ];
          binName = "consumer-pi";
          skills = [ (inputs.consumer-data + "/skills") ];
          appendSystemPrompts = [ "Independent consumer instructions." ];
          mcpServers = lib.mkForce { };
        };
        flake.modules.homeManager.consumer-pi = { pkgs, ... }: {
          home.packages = [ (config.flake.wrappers.consumer-pi.wrap { inherit pkgs; }) ];
        };

        flake.nixosConfigurations.fixture = mkHost {
          buckets = [
            "base"
            "dev"
            "ai"
            "skills"
            "consumer-pi"
          ];
          modules = [
            {
              boot.isContainer = true;
              networking.hostName = "fixture";
              system.stateVersion = "24.11";
              programs.nh.flake = "/home/consumer/config";
              home-manager.users.consumer.my.ai.copilot-cli.enable = true;
            }
          ];
        };

        flake.consumerContract =
          let
            c = config.flake.nixosConfigurations.fixture.config;
            h = c.home-manager.users.consumer;
            copilot = lib.findFirst (p: (p.name or "") == "copilot-wrapped") null h.home.packages;
            skills = h.programs.agent-skills;
            commonSkillNames = builtins.attrNames (
              lib.filterAttrs (_: skill: skill.source == "nix-common") skills.catalog
            );
            consumerOwnedSkills = [
              "ado-pr-markdown"
              "browser-control"
              "figma-to-spec"
              "fluent-ui-v9"
            ];
          in
          assert c.environment.variables.CONSUMER_MARKER == "consumer-owned\n";
          assert h.home.sessionVariables.CONSUMER_MARKER == "consumer-owned\n";
          assert h.home.username == "consumer";
          assert h.home.homeDirectory == "/home/consumer";
          assert h.home.stateVersion == "24.11";
          assert h.programs.git.settings.user.email == "consumer@example.invalid";
          assert lib.elem "consumer-skill" skills.skills.enable;
          assert lib.elem "unslop" skills.skills.enable;
          assert skills.catalog.unslop.source == "unslop";
          assert skills.catalog.unslop.relPath == "";
          assert toString skills.sources.unslop.path == toString inputs.nix-common.inputs.unslop;
          assert lib.any (
            p: p.outPath == config.flake.nixosConfigurations.fixture.pkgs.python3.outPath
          ) h.home.packages;
          assert
            commonSkillNames == [
              "context-reflect"
              "html-report"
              "writing-skills"
            ];
          assert lib.all (name: lib.elem name skills.skills.enable) commonSkillNames;
          assert lib.all (
            name: !(builtins.hasAttr name skills.catalog) && !(lib.elem name skills.skills.enable)
          ) consumerOwnedSkills;
          assert !lib.elem "warehouse-ux-pr-review" skills.skills.enable;
          assert h.sops.secrets == { };
          assert h.sops.templates == { };
          assert copilot != null;
          assert !(skills.sources ? pi-nix-wrapper);
          assert !(skills.catalog ? mk-pi-extension);
          assert skills.skills.enableAll == false;
          assert !(config.flake.modules.homeManager ? pi-next);
          assert !(config.flake.modules.nixos ? pi-next);
          assert lib.any (
            p:
            p.outPath == (config.flake.wrappers.consumer-pi.wrap {
              pkgs = config.flake.nixosConfigurations.fixture.pkgs;
            }).outPath
          ) h.home.packages;
          {
            passed = true;
            copilotDerivation = copilot.drvPath;
            homeFiles = builtins.attrNames h.home.file;
          };

        perSystem =
          { pkgs, ... }@system:
          {
            checks.consumer-skills =
              let
                skills =
                  config.flake.nixosConfigurations.fixture.config.home-manager.users.consumer.programs.agent-skills;
              in
              pkgs.runCommand "consumer-skills" { nativeBuildInputs = [ pkgs.python3 ]; } ''
                skill=${skills.targetBundlePaths.agents}/unslop
                test -f "$skill/SKILL.md"
                test -f "$skill/references/core-contract.md"
                test -f "$skill/references/packs/manifest.json"
                test -f "$skill/presets/crisp-human.md"
                for command in cleanup rewrite teach mimic; do
                  test -f "$skill/references/commands/$command.md"
                done
                # Run outside the source tree to exercise bundled resource resolution.
                export PYTHONDONTWRITEBYTECODE=1
                printf 'The file contains 12 rows.\n' | python3 "$skill/scripts/banned_phrase_scan.py" > scan.json
                python3 -c 'import json; assert json.load(open("scan.json"))["total_violations"] == 0'
                touch "$out"
              '';
            checks.consumer-wrapper = pkgs.runCommand "consumer-wrapper" { } ''
              ${system.config.packages.tmux}/bin/consumer-tmux -V | grep tmux
              touch "$out"
            '';
            checks.consumer-pi =
              assert !(system.config.packages ? pi-next);
              pkgs.runCommand "consumer-pi" { nativeBuildInputs = [ pkgs.jq ]; } ''
                bash ${../tests/pi-next/consumer.sh} ${system.config.packages.consumer-pi} ${../tests/pi-next/probe.ts}
                touch "$out"
              '';
          };
      }
    );
}
