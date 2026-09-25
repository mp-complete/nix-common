{ lib, ... }:
{
  flake.modules.homeManager.noctalia =
    { config, ... }:
    let
      wallpapers = "${config.home.homeDirectory}/Pictures/Wallpapers";
      settings = builtins.replaceStrings [ "@WALLPAPERS@" ] [ wallpapers ] (
        builtins.readFile ./noctalia-config.toml
      );
    in
    {
      imports = [ builtins.scoped.commonInputs.noctalia.homeModules.default ];

      programs.noctalia = {
        enable = true;
        systemd.enable = false;
        settings = builtins.toFile "noctalia-config.toml" settings;
      };
    };
}
