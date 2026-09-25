{
  flake.modules.nixos.desktop-core = {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.powerOnBoot = true;
    # Disable ERTM to fix Xbox controller Bluetooth reconnect loop.
    boot.extraModprobeConfig = "options bluetooth disable_ertm=Y";
  };
}
