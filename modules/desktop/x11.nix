{ config, ... }:
{
  # X11 layer: imports desktop-core, adds the X server + a graphical login.
  flake.modules.nixos.desktop-x11 = {
    imports = [ config.flake.modules.nixos.desktop-core ];

    services.xserver.enable = true;
    services.xserver.displayManager.lightdm.enable = true;
  };
}
