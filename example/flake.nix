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

        flake.nixosConfigurations.fixture = mkHost {
          buckets = [
            "base"
            "dev"
            "ai"
            "skills"
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
          in
          assert c.environment.variables.CONSUMER_MARKER == "consumer-owned\n";
          assert h.home.sessionVariables.CONSUMER_MARKER == "consumer-owned\n";
          assert h.home.username == "consumer";
          assert h.home.homeDirectory == "/home/consumer";
          assert h.home.stateVersion == "24.11";
          assert h.programs.git.settings.user.email == "consumer@example.invalid";
          assert lib.elem "consumer-skill" h.programs.agent-skills.skills.enable;
          assert !lib.elem "warehouse-ux-pr-review" h.programs.agent-skills.skills.enable;
          assert h.sops.secrets == { };
          assert h.sops.templates == { };
          assert copilot != null;
          {
            passed = true;
            copilotDerivation = copilot.drvPath;
            homeFiles = builtins.attrNames h.home.file;
          };

        perSystem = { config, pkgs, ... }: {
          checks.consumer-wrapper = pkgs.runCommand "consumer-wrapper" { } ''
            ${config.packages.tmux}/bin/consumer-tmux -V | grep tmux
            touch "$out"
          '';
        };
      }
    );
}
