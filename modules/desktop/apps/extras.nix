{
  # General desktop applications shared across desktop hosts (euler + laplace).
  flake.modules.homeManager.desktop-core =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        thunderbird
        vlc
        kvirc
        evtest
      ];
    };
}
