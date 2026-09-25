{ lib, ... }:
{
  flake.modules.nixos.hardware =
    { config, ... }:
    {
      hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    };
}
