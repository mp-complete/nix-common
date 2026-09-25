{ config, ... }:
{
  flake.modules.nixos.virt =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        spice
        spice-gtk
        swtpm
      ];
      virtualisation.libvirtd = {
        enable = true;
        qemu.swtpm.enable = true;
      };
      virtualisation.spiceUSBRedirection.enable = true;
      programs.virt-manager.enable = true;
      services.spice-vdagentd.enable = true;
      users.users.${config.username}.extraGroups = [ "libvirtd" ];
    };
}
