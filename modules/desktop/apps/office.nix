{
  flake.modules.homeManager.desktop-core =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        libreoffice-qt
        hunspell
        hunspellDicts.en_US-large
      ];
    };
}
