{ lib, ... }:
{
  # @lumendigitaldev/pi-wsl-images — Alt+V image paste from the Windows
  # clipboard. Most useful on WSL hosts where pi can't see X11/Wayland
  # clipboards directly.
  # https://github.com/lumendigitaldev/pi-wsl-images
  pi.extensions.pi-wsl-images = {
    pname = "@lumendigitaldev/pi-wsl-images";
    version = "1.0.1";
    hash = "sha512-qiE+LW/iKOm4p3OYWa707qwHGCwKSEoLVFXhYy5IVwNAp9uX8l4k2jo01xBaMLwJEbTyIcCx2MN62TsCCpg1Eg==";
    meta.platforms = lib.platforms.linux; # WSL-specific
  };
}
