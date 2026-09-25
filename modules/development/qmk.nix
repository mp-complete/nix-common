{
  # QMK keyboard firmware development. Opt-in: hosts import the `qmk` bucket.
  # Pulls the CLI plus the udev rules that let you flash boards without root.
  flake.modules.nixos.qmk =
    { pkgs, ... }:
    {
      hardware.keyboard.qmk.enable = true;
      environment.systemPackages = [ pkgs.qmk ];
    };
}
