{
  # Opt-in: hosts using EFI/systemd-boot import `hardware`.
  flake.modules.nixos.hardware = {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "ahci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];
    boot.kernelModules = [ "kvm-amd" ];
    boot.supportedFilesystems = [
      "ntfs"
      "cifs"
    ];
  };
}
