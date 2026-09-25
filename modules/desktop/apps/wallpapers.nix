{
  flake.modules.homeManager.desktop-core = {
    # Per-monitor wallpaper folders. noctalia 5.x uses the capital-W
    # ~/Pictures/Wallpapers base and per-output subdirectories.
    home.file."Pictures/Wallpapers/Horizontal" = {
      source = ./_wallpapers/Horizontal;
      recursive = true;
    };
    home.file."Pictures/Wallpapers/Vertical" = {
      source = ./_wallpapers/Vertical;
      recursive = true;
    };
  };
}
