{ lib, ... }:
{
  flake.modules.nixos.hardware = {
    hardware.enableRedistributableFirmware = lib.mkDefault true;
  };
}
