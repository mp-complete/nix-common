{ secretSource, sopsModule }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.my.ai;
in
{
  imports = [ sopsModule ];

  config = lib.mkIf (cfg.copilot-cli.enable && secretSource != null) {
    sops = {
      age.keyFile = lib.mkDefault "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      secrets.github.sopsFile = secretSource;
      templates."ai-env".content = "export COPILOT_GITHUB_TOKEN=${config.sops.placeholder.github}";
    };
  };
}
