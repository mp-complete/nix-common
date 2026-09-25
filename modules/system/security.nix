{
  flake.modules.nixos.base = {
    security.rtkit.enable = true;
    security.sudo.enable = true;
  };
}
