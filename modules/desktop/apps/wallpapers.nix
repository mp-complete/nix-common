{
  flake.modules.homeManager.desktop-core = {
    # Shared wallpaper assets for downstream desktop shells.
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
