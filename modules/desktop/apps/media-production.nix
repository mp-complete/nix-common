{
  # Media production / content creation (euler workstation).
  # Opt-in: hosts import the `media-production` bucket.
  flake.modules.homeManager.media-production =
    { pkgs, ... }:
    {
      programs.obs-studio.enable = true;

      home.packages = with pkgs; [
        gimp
        ffmpeg-full
      ];
    };
}
