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
        # Noctalia treats strings as raw TOML. builtins.toFile returns a string,
        # so passing its store path would write that path as the config contents.
        inherit settings;
      };
    };
}
