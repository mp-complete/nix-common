{ lib, config, ... }:
{
  # The one cross-cutting identity value, read by ssh, syncthing, openclaw, etc.
  options.username = lib.mkOption {
    type = lib.types.str;
    description = "Primary user account name (required from the consumer).";
  };

  config.flake.modules.nixos.base =
    { pkgs, ... }:
    {
      users.defaultUserShell = pkgs.bash;
      users.users.${config.username} = {
        isNormalUser = true;
        description = config.username;
        extraGroups = [
          "networkmanager"
          "wheel"
          "input"
        ];
      };
    };
}
