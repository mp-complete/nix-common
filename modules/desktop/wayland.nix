{ config, ... }:
{
  # Wayland layer: imports desktop-core, adds wayland session tooling + greeter.
  flake.modules.nixos.desktop-wayland =
    { pkgs, ... }:
    {
      imports = [ config.flake.modules.nixos.desktop-core ];

      environment.pathsToLink = [ "/share/wayland-sessions" ];
      services.geoclue2.enable = true;
      services.accounts-daemon.enable = true;

      # tuigreet picks a wayland session (sway, niri, …) at login.
      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --sessions /run/current-system/sw/share/wayland-sessions";
          user = "greeter";
        };
      };
      security.pam.services.greetd.enableGnomeKeyring = true;
    };

  flake.modules.homeManager.desktop-wayland =
    { pkgs, ... }:
    {
      imports = [ config.flake.modules.homeManager.desktop-core ];
      home.packages = with pkgs; [
        wl-clipboard
        grim
        slurp
        swappy
        cliphist
      ];
    };
}
