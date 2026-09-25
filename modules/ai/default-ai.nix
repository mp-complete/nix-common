{ config, lib, ... }:
let
  secretSource = config.ai.secretSource;
in
{
  options.ai.secretSource = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = "Consumer-owned encrypted YAML containing AI API keys; null disables AI secret declarations.";
  };

  config.flake.modules.homeManager.ai = {
    imports = [
      ./_impl/options.nix
      (import ./_impl/secrets.nix {
        inherit secretSource;
        sopsModule = builtins.scoped.commonInputs.sops-nix.homeManagerModules.sops;
      })
      ./_impl/copilot-cli.nix
    ];
  };
}
