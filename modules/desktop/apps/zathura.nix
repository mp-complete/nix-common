{
  flake.modules.homeManager.desktop-core =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.zathura ];
    };
}
