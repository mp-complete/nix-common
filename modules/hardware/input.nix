{
  # Keyboard layout — shared by X11, wayland and the console.
  flake.modules.nixos.desktop-core = {
    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };
    console.useXkbConfig = true;
  };
}
