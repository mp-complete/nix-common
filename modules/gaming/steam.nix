{
  # Gaming (euler workstation). Opt-in: hosts import the `gaming` bucket.
  flake.modules.nixos.gaming =
    { pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        localNetworkGameTransfers.openFirewall = true;
        gamescopeSession.enable = true;
        extraCompatPackages = with pkgs; [ proton-ge-bin ];
        package = pkgs.steam.override {
          # Provide 32-bit PulseAudio client libs so Steam uses the system audio
          # stack instead of its ancient bundled libpulse + libaudio.so (which
          # segfaults on modern PipeWire systems).
          extraLibraries = p: [ p.libpulseaudio ];
        };
      };

      programs.gamescope = {
        enable = true;
        capSysNice = true;
      };

      programs.gamemode.enable = true;

      environment.systemPackages = with pkgs; [
        mangohud
        steamtinkerlaunch
      ];
    };
}
