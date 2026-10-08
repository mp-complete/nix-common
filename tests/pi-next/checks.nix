{
  config,
  inputs,
  lib,
  ...
}:
let
  outer = config;
in
{
  perSystem =
    { config, pkgs, ... }:
    let
      extensions = (pkgs.extend outer.flake.overlays.pi-next-extensions).piExtensions;
      # Keep skill loading independently testable while npm extensions evolve.
      skillsOnly = outer.flake.wrappers.pi-next.wrap {
        inherit pkgs;
        piPackages = lib.mkForce [ ];
        extensions = lib.mkForce [ ];
        # Skill discovery must not connect to declared remote servers.
        mcpServers = lib.mkForce { };
      };
      standalone = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          outer.flake.modules.homeManager.pi-next
          {
            home.username = "pi-next-test";
            home.homeDirectory = "/home/pi-next-test";
            home.stateVersion = "24.11";
            # Exercise Home Manager's actual package merge with the legacy Pi.
            home.packages = [ config.packages.pi-wsl ];
          }
        ];
      };
    in
    {
      checks.pi-next-coexistence = standalone.config.home.path;

      checks.pi-next-notify = pkgs.runCommand "pi-next-notify" { nativeBuildInputs = [ pkgs.nodejs ]; } ''
        node --disable-warning=ExperimentalWarning ${./notify.mjs} ${extensions.pi-notify-official}
        touch "$out"
      '';

      checks.pi-next-skills =
        pkgs.runCommand "pi-next-skills-smoke" { nativeBuildInputs = [ pkgs.jq ]; }
          ''
            bash ${./skills.sh} ${skillsOnly} ${./probe.ts}
            touch "$out"
          '';

      checks.pi-next =
        assert lib.any (p: p.outPath == config.packages.pi-next.outPath) standalone.config.home.packages;
        pkgs.runCommand "pi-next-smoke" { nativeBuildInputs = [ pkgs.jq ]; } ''
          bash ${./smoke.sh} ${config.packages.pi-next} ${./probe.ts} ${extensions.pi-interactive-shell} ${extensions.pi-notify-official} ${extensions.rpiv-ask-user-question} ${extensions.plannotator} ${extensions.rpiv-todo}
          touch "$out"
        '';
    };
}
