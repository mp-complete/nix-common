{
  flake.modules.homeManager.desktop-core =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        discord
        spotify
      ];
    };
}
