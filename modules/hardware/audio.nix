{
  # Pipewire audio is part of any graphical host → desktop-core.
  flake.modules.nixos.desktop-core = {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };
}
