{
  # System firefox (nixos side) + the package is graphical → desktop-core.
  flake.modules.nixos.desktop-core = {
    programs.firefox.enable = true;
  };
}
