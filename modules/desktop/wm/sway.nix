{ config, ... }:
{
  # Sway (Wayland) — provides the compositor/session selected by Laplace and
  # pulls in the shared Wayland desktop layers on both sides.
  flake.modules.nixos.sway = {
    imports = [ config.flake.modules.nixos.desktop-wayland ];

    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };
  };

  flake.modules.homeManager.sway = {
    imports = [ config.flake.modules.homeManager.desktop-wayland ];
  };
}
